//
//  Keychain.swift
//  OneTimePassword
//
//  Copyright (c) 2014-2015 OneTimePassword authors
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
    /// - returns: The persistent token, or `nil` if no token matched the given identifier.
    public func persistentTokenWithIdentifier(identifier: NSData) -> PersistentToken? {
        guard let result = keychainItemForPersistentRef(identifier) else {
            return nil
        }
        return PersistentToken(keychainDictionary: result)
    }

    /// Returns an array of all persistent tokens found in the keychain.
    public func allPersistentTokens() -> [PersistentToken]? {
        guard let keychainItems = (try? allKeychainItems()) as? [NSDictionary] else {
            return nil
        }
        return keychainItems.flatMap({ PersistentToken(keychainDictionary: $0) })
    }

    // MARK: Write

    /// Adds the given token to the keychain and returns the persistent token which contains it.
    ///
    /// - parameter token: The token to save to the keychain.
    ///
    /// - returns: The new persistent token, or `nil` if an error has occured.
    public func addToken(token: Token) -> PersistentToken? {
        guard let attributes = token.keychainAttributes,
            persistentRef = addKeychainItemWithAttributes(attributes) else {
                return nil
        }
        return PersistentToken(token: token, identifier: persistentRef)
    }

    /// Updates the given persistent token with a new token value.
    ///
    /// - parameter persistentToken: The persistent token to update.
    /// - parameter token: The new token value.
    ///
    /// - returns: The updated persistent token, or `nil` if an error has occured.
    public func updatePersistentToken(persistentToken: PersistentToken,
        withToken token: Token) -> PersistentToken?
    {
        guard let attributes = token.keychainAttributes else {
            return nil
        }
        let success = updateKeychainItemForPersistentRef(persistentToken.identifier,
            withAttributes: attributes)
        guard success else {
            return nil
        }
        return PersistentToken(token: token, identifier: persistentToken.identifier)
    }

    /// Deletes the given persistent token from the keychain.
    ///
    /// - note: After calling `deletePersistentToken(_:)`, the persistent token's `identifier` is no
    ///         longer valid, and the token should be discarded.
    ///
    /// - parameter persistentToken: The persistent token to delete.
    ///
    /// - returns: A boolean indicating whether the token was successfully deleted.
    public func deletePersistentToken(persistentToken: PersistentToken) -> Bool {
        return deleteKeychainItemForPersistentRef(persistentToken.identifier)
    }

    // MARK: Errors

    public enum Error: ErrorType {
        case SystemError(OSStatus)
        case IncorrectReturnType
    }
}

// MARK: - Private

private let kOTPService = "me.mattrubin.onetimepassword.token"

private extension Token {
    private var keychainAttributes: [String: AnyObject]? {
        guard let url = Token.URLSerializer.serialize(self),
            let data = url.absoluteString.dataUsingEncoding(NSUTF8StringEncoding) else {
                return nil
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
            let token = Token.URLSerializer.deserialize(url, secret: secret) else {
                return nil
        }
        self.init(token: token, identifier: keychainItemRef)
    }
}

private func addKeychainItemWithAttributes(attributes: NSDictionary) -> NSData? {
    guard let mutableAttributes = attributes.mutableCopy() as? NSMutableDictionary else {
        return nil
    }
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

    guard resultCode == OSStatus(errSecSuccess) else {
        return nil
    }
    return result as? NSData
}

private func updateKeychainItemForPersistentRef(persistentRef: NSData,
    withAttributes attributesToUpdate: NSDictionary) -> Bool
{
    let queryDict = [
        kSecClass as String:               kSecClassGenericPassword,
        kSecValuePersistentRef as String:  persistentRef,
    ]

    let resultCode = SecItemUpdate(queryDict, attributesToUpdate)
    return (resultCode == OSStatus(errSecSuccess))
}

private func deleteKeychainItemForPersistentRef(persistentRef: NSData) -> Bool {
    let queryDict = [
        kSecClass as String:               kSecClassGenericPassword,
        kSecValuePersistentRef as String:  persistentRef,
    ]

    let resultCode = SecItemDelete(queryDict)
    return (resultCode == OSStatus(errSecSuccess))
}

private func keychainItemForPersistentRef(persistentRef: NSData) -> NSDictionary? {
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

    guard resultCode == OSStatus(errSecSuccess) else {
        return nil
    }
    return result as? NSDictionary
}

private func allKeychainItems() throws -> NSArray {
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
    guard let keychainItems = result as? NSArray else {
        throw Keychain.Error.IncorrectReturnType
    }
    return keychainItems
}
