//
//  Keychain.swift
//  OneTimePassword
//
//  Copyright (c) 2014-2017 Matt Rubin and the OneTimePassword authors
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
    /// - parameter identifier: The persistent identifier for the desired token.
    ///
    /// - throws: A `Keychain.Error` if an error occurred.
    /// - returns: The persistent token, or `nil` if no token matched the given identifier.
    public func persistentToken(withIdentifier identifier: Data) throws -> PersistentToken? {
        return try keychainItem(forPersistentRef: identifier).map(PersistentToken.init(keychainDictionary:))
    }

    /// Returns the set of all persistent tokens found in the keychain.
    ///
    /// - throws: A `Keychain.Error` if an error occurred.
    public func allPersistentTokens() throws -> Set<PersistentToken> {
        let allItems = try allKeychainItems()
        // This code intentionally ignores items which fail deserialization, instead opting to return as many readable
        // tokens as possible.
        // TODO: Restore deserialization error handling, in a way that provides info on the failure reason and allows
        //       the caller to choose whether to fail completely or recover some data.
        return Set(allItems.flatMap({ try? PersistentToken(keychainDictionary: $0) }))
    }

    // MARK: Write

    /// Adds the given token to the keychain and returns the persistent token which contains it.
    ///
    /// - parameter token: The token to save to the keychain.
    ///
    /// - throws: A `Keychain.Error` if the token was not added successfully.
    /// - returns: The new persistent token.
    public func add(_ token: Token) throws -> PersistentToken {
        let attributes = try token.keychainAttributes()
        let persistentRef = try addKeychainItem(withAttributes: attributes)
        return PersistentToken(token: token, identifier: persistentRef)
    }

    /// Updates the given persistent token with a new token value.
    ///
    /// - parameter persistentToken: The persistent token to update.
    /// - parameter token: The new token value.
    ///
    /// - throws: A `Keychain.Error` if the update did not succeed.
    /// - returns: The updated persistent token.
    public func update(_ persistentToken: PersistentToken, with token: Token) throws -> PersistentToken {
        let attributes = try token.keychainAttributes()
        try updateKeychainItem(forPersistentRef: persistentToken.identifier,
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
    public func delete(_ persistentToken: PersistentToken) throws {
        try deleteKeychainItem(forPersistentRef: persistentToken.identifier)
    }

    // MARK: Errors

    /// An error type enum representing the various errors a `Keychain` operation can throw.
    public enum Error: Swift.Error {
        /// The keychain operation returned a system error code.
        case systemError(OSStatus)
        /// The keychain operation returned an unexpected type of data.
        case incorrectReturnType
        /// The given token could not be serialized to keychain data.
        case tokenSerializationFailure
    }
}

// MARK: - Private

private let kOTPService = "me.mattrubin.onetimepassword.token"
private let urlStringEncoding = String.Encoding.utf8

private extension Token {
    func keychainAttributes() throws -> [String: AnyObject] {
        let url = try self.toURL()
        guard let data = url.absoluteString.data(using: urlStringEncoding) else {
            throw Keychain.Error.tokenSerializationFailure
        }
        return [
            kSecAttrGeneric as String:  data as NSData,
            kSecValueData as String:    generator.secret as NSData,
            kSecAttrService as String:  kOTPService as NSString,
        ]
    }
}

private extension PersistentToken {
    enum DeserializationError: Error {
        case missingData
        case missingSecret
        case missingPersistentRef
        case unreadableData
    }

    init(keychainDictionary: NSDictionary) throws {
        guard let urlData = keychainDictionary[kSecAttrGeneric as String] as? Data else {
            throw DeserializationError.missingData
        }
        guard let secret = keychainDictionary[kSecValueData as String] as? Data else {
            throw DeserializationError.missingSecret
        }
        guard let keychainItemRef = keychainDictionary[kSecValuePersistentRef as String] as? Data else {
            throw DeserializationError.missingPersistentRef
        }
        guard let urlString = String(data: urlData, encoding: urlStringEncoding),
            let url = URL(string: urlString) else {
                throw DeserializationError.unreadableData
        }
        let token = try Token(_url: url, secret: secret)
        self.init(token: token, identifier: keychainItemRef)
    }
}

private func addKeychainItem(withAttributes attributes: [String: AnyObject]) throws -> Data {
    var mutableAttributes = attributes
    mutableAttributes[kSecClass as String] = kSecClassGenericPassword
    mutableAttributes[kSecReturnPersistentRef as String] = kCFBooleanTrue
    // Set a random string for the account name.
    // We never query by or display this value, but the keychain requires it to be unique.
    if mutableAttributes[kSecAttrAccount as String] == nil {
        mutableAttributes[kSecAttrAccount as String] = UUID().uuidString as NSString
    }

    var result: AnyObject?
    let resultCode: OSStatus = withUnsafeMutablePointer(to: &result) {
        SecItemAdd(mutableAttributes as CFDictionary, $0)
    }

    guard resultCode == errSecSuccess else {
        throw Keychain.Error.systemError(resultCode)
    }
    guard let persistentRef = result as? Data else {
        throw Keychain.Error.incorrectReturnType
    }
    return persistentRef
}

private func updateKeychainItem(forPersistentRef persistentRef: Data,
                                withAttributes attributesToUpdate: [String: AnyObject]) throws {
    let queryDict: [String: AnyObject] = [
        kSecClass as String:               kSecClassGenericPassword,
        kSecValuePersistentRef as String:  persistentRef as NSData,
    ]

    let resultCode = SecItemUpdate(queryDict as CFDictionary, attributesToUpdate as CFDictionary)

    guard resultCode == errSecSuccess else {
        throw Keychain.Error.systemError(resultCode)
    }
}

private func deleteKeychainItem(forPersistentRef persistentRef: Data) throws {
    let queryDict: [String: AnyObject] = [
        kSecClass as String:               kSecClassGenericPassword,
        kSecValuePersistentRef as String:  persistentRef as NSData,
    ]

    let resultCode = SecItemDelete(queryDict as CFDictionary)

    guard resultCode == errSecSuccess else {
        throw Keychain.Error.systemError(resultCode)
    }
}

private func keychainItem(forPersistentRef persistentRef: Data) throws -> NSDictionary? {
    let queryDict: [String: AnyObject] = [
        kSecClass as String:                kSecClassGenericPassword,
        kSecValuePersistentRef as String:   persistentRef as NSData,
        kSecReturnPersistentRef as String:  kCFBooleanTrue,
        kSecReturnAttributes as String:     kCFBooleanTrue,
        kSecReturnData as String:           kCFBooleanTrue,
    ]

    var result: AnyObject?
    let resultCode = withUnsafeMutablePointer(to: &result) {
        SecItemCopyMatching(queryDict as CFDictionary, $0)
    }

    if resultCode == errSecItemNotFound {
        // Not finding any keychain items is not an error in this case. Return nil.
        return nil
    }
    guard resultCode == errSecSuccess else {
        throw Keychain.Error.systemError(resultCode)
    }
    guard let keychainItem = result as? NSDictionary else {
        throw Keychain.Error.incorrectReturnType
    }
    return keychainItem
}

private func allKeychainItems() throws -> [NSDictionary] {
    let queryDict: [String: AnyObject] = [
        kSecClass as String:                kSecClassGenericPassword,
        kSecMatchLimit as String:           kSecMatchLimitAll,
        kSecReturnPersistentRef as String:  kCFBooleanTrue,
        kSecReturnAttributes as String:     kCFBooleanTrue,
        kSecReturnData as String:           kCFBooleanTrue,
    ]

    var result: AnyObject?
    let resultCode = withUnsafeMutablePointer(to: &result) {
        SecItemCopyMatching(queryDict as CFDictionary, $0)
    }

    if resultCode == errSecItemNotFound {
        // Not finding any keychain items is not an error in this case. Return an empty array.
        return []
    }
    guard resultCode == errSecSuccess else {
        throw Keychain.Error.systemError(resultCode)
    }
    guard let keychainItems = result as? [NSDictionary] else {
        throw Keychain.Error.incorrectReturnType
    }
    return keychainItems
}
