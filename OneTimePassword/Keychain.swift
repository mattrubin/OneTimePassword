//
//  Keychain.swift
//  OneTimePassword
//
//  Copyright (c) 2014-2015 Matt Rubin and the OneTimePassword authors
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

/// The `Keychain`'s shared instance is a singleton which represents the iOS system keychain used
/// to securely store tokens.
public final class Keychain {
    /// The singleton `Keychain` instance.
    public static let sharedInstance = Keychain()

    // MARK: Read

    /// Finds the persistent token with the given identifer, if one exists.
    ///
    /// - parameter token: The persistent identifier for the desired token.
    ///
    /// - throws: A `Keychain.Error` if an error occurred.
    /// - returns: The persistent token, or `nil` if no token matched the given identifier.
    public func persistentTokenWithIdentifier(identifier: NSData) throws -> PersistentToken? {
        return try keychainItemForPersistentRef(identifier).flatMap(PersistentToken.init)
    }

    /// Returns the set of all persistent tokens found in the keychain.
    ///
    /// - throws: A `Keychain.Error` if an error occurred.
    public func allPersistentTokens() throws -> Set<PersistentToken> {
        return Set(try allKeychainItems().flatMap(PersistentToken.init))
    }

    // MARK: Write

    /// Adds the given token to the keychain and returns the persistent token which contains it.
    ///
    /// - parameter token: The token to save to the keychain.
    ///
    /// - throws: A `Keychain.Error` if the token was not added successfully.
    /// - returns: The new persistent token.
    public func addToken(token: Token) throws -> PersistentToken {
        let attributes = try token.keychainAttributes()
        let persistentRef = try addKeychainItemWithAttributes(attributes)
        return PersistentToken(token: token, identifier: persistentRef)
    }

    /// Updates the given persistent token with a new token value.
    ///
    /// - parameter persistentToken: The persistent token to update.
    /// - parameter token: The new token value.
    ///
    /// - throws: A `Keychain.Error` if the update did not succeed.
    /// - returns: The updated persistent token.
    public func updatePersistentToken(persistentToken: PersistentToken,
        withToken token: Token) throws -> PersistentToken
    {
        let attributes = try token.keychainAttributes()
        try updateKeychainItemForPersistentRef(persistentToken.identifier,
            withAttributes: attributes)
        return PersistentToken(token: token, identifier: persistentToken.identifier)
    }

    /// Deletes the given persistent token from the keychain.
    ///
    /// - note: After calling `deletePersistentToken(_:)`, the persistent token's `identifier` is no
    ///         longer valid, and the token should be discarded.
    ///
    /// - parameter persistentToken: The persistent token to delete.
    ///
    /// - throws: A `Keychain.Error` if the deletion did not succeed.
    public func deletePersistentToken(persistentToken: PersistentToken) throws {
        try deleteKeychainItemForPersistentRef(persistentToken.identifier)
    }

    // MARK: Errors

    public enum Error: ErrorType {
        case SystemError(OSStatus)
        case IncorrectReturnType
        case TokenSerializationFailure
    }
}

// MARK: - Private

private let kOTPService = "me.mattrubin.onetimepassword.token"

private extension Token {
    private func keychainAttributes() throws -> [String: AnyObject] {
        let url = try self.toURL()
        guard let data = url.absoluteString.dataUsingEncoding(NSUTF8StringEncoding) else {
            throw Keychain.Error.TokenSerializationFailure
        }
        return [
            kSecAttrGeneric as String:  data,
            kSecValueData as String:    generator.secret,
            kSecAttrService as String:  kOTPService,
        ]
    }
}

private extension PersistentToken {
    private init?(keychainDictionary: NSDictionary) {
        guard let urlData = keychainDictionary[kSecAttrGeneric as String] as? NSData,
            let string = NSString(data: urlData, encoding:NSUTF8StringEncoding),
            let secret = keychainDictionary[kSecValueData as String] as? NSData,
            let keychainItemRef = keychainDictionary[kSecValuePersistentRef as String] as? NSData,
            let url = NSURL(string: string as String),
            let token = Token(url: url, secret: secret) else {
                return nil
        }
        self.init(token: token, identifier: keychainItemRef)
    }
}

private func addKeychainItemWithAttributes(attributes: [String: AnyObject]) throws -> NSData {
    var mutableAttributes = attributes
    mutableAttributes[kSecClass as String] = kSecClassGenericPassword
    mutableAttributes[kSecReturnPersistentRef as String] = kCFBooleanTrue
    // Set a random string for the account name.
    // We never query by or display this value, but the keychain requires it to be unique.
    if mutableAttributes[kSecAttrAccount as String] == nil {
        mutableAttributes[kSecAttrAccount as String] = NSUUID().UUIDString
    }

    var result: AnyObject?
    let resultCode: OSStatus = withUnsafeMutablePointer(&result) {
        SecItemAdd(mutableAttributes, $0)
    }

    guard resultCode == errSecSuccess else {
        throw Keychain.Error.SystemError(resultCode)
    }
    guard let persistentRef = result as? NSData else {
        throw Keychain.Error.IncorrectReturnType
    }
    return persistentRef
}

private func updateKeychainItemForPersistentRef(persistentRef: NSData,
    withAttributes attributesToUpdate: [String: AnyObject]) throws
{
    let queryDict = [
        kSecClass as String:               kSecClassGenericPassword,
        kSecValuePersistentRef as String:  persistentRef,
    ]

    let resultCode = SecItemUpdate(queryDict, attributesToUpdate)

    guard resultCode == errSecSuccess else {
        throw Keychain.Error.SystemError(resultCode)
    }
}

private func deleteKeychainItemForPersistentRef(persistentRef: NSData) throws {
    let queryDict = [
        kSecClass as String:               kSecClassGenericPassword,
        kSecValuePersistentRef as String:  persistentRef,
    ]

    let resultCode = SecItemDelete(queryDict)

    guard resultCode == errSecSuccess else {
        throw Keychain.Error.SystemError(resultCode)
    }
}

private func keychainItemForPersistentRef(persistentRef: NSData) throws -> NSDictionary? {
    let queryDict = [
        kSecClass as String:                kSecClassGenericPassword,
        kSecValuePersistentRef as String:   persistentRef,
        kSecReturnPersistentRef as String:  kCFBooleanTrue,
        kSecReturnAttributes as String:     kCFBooleanTrue,
        kSecReturnData as String:           kCFBooleanTrue,
    ]

    var result: AnyObject?
    let resultCode = withUnsafeMutablePointer(&result) {
        SecItemCopyMatching(queryDict, $0)
    }

    if resultCode == errSecItemNotFound {
        // Not finding any keychain items is not an error in this case. Return nil.
        return nil
    }
    guard resultCode == errSecSuccess else {
        throw Keychain.Error.SystemError(resultCode)
    }
    guard let keychainItem = result as? NSDictionary else {
        throw Keychain.Error.IncorrectReturnType
    }
    return keychainItem
}

private func allKeychainItems() throws -> [NSDictionary] {
    let queryDict = [
        kSecClass as String:                kSecClassGenericPassword,
        kSecMatchLimit as String:           kSecMatchLimitAll,
        kSecReturnPersistentRef as String:  kCFBooleanTrue,
        kSecReturnAttributes as String:     kCFBooleanTrue,
        kSecReturnData as String:           kCFBooleanTrue,
    ]

    var result: AnyObject?
    let resultCode = withUnsafeMutablePointer(&result) {
        SecItemCopyMatching(queryDict, $0)
    }

    if resultCode == errSecItemNotFound {
        // Not finding any keychain items is not an error in this case. Return an empty array.
        return []
    }
    guard resultCode == errSecSuccess else {
        throw Keychain.Error.SystemError(resultCode)
    }
    guard let keychainItems = result as? [NSDictionary] else {
        throw Keychain.Error.IncorrectReturnType
    }
    return keychainItems
}
