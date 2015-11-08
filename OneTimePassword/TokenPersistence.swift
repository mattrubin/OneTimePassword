//
//  TokenPersistence.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/9/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import Foundation

let kOTPService = "me.mattrubin.onetimepassword.token"

public extension Token {
    public struct KeychainItem {
        public let token: Token
        public let persistentRef: NSData

        init(token: Token, persistentRef: NSData) {
            self.token = token
            self.persistentRef = persistentRef
        }

        public init?(keychainItemRef: NSData) {
            guard let result = keychainItemForPersistentRef(keychainItemRef) else {
                return nil
            }
            self.init(keychainDictionary: result)
        }

        public init?(keychainDictionary: NSDictionary) {
            guard let urlData = keychainDictionary[kSecAttrGeneric as String] as? NSData,
                let string = NSString(data: urlData, encoding:NSUTF8StringEncoding),
                let secret = keychainDictionary[kSecValueData as String] as? NSData,
                let keychainItemRef = keychainDictionary[kSecValuePersistentRef as String] as? NSData,
                let url = NSURL(string: string as String),
                let token = Token.URLSerializer.deserialize(url, secret: secret)
                else { return nil }

            self.init(token: token, persistentRef: keychainItemRef)
        }

        public static func allKeychainItems() -> Array<KeychainItem> {
            guard let keychainItems = _allKeychainItems() else {
                return []
            }
            var items = Array<KeychainItem>()
            for item: AnyObject in keychainItems {
                if let keychainDict = item as? NSDictionary,
                    let keychainItem = KeychainItem(keychainDictionary: keychainDict) {
                        items.append(keychainItem)
                }
            }
            return items
        }
    }
}

func keychainItemForPersistentRef(persistentRef: NSData) -> NSDictionary? {
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

func _allKeychainItems() -> NSArray? {
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

    guard resultCode == OSStatus(errSecSuccess) else {
        return nil
    }
    return result as? NSArray
}


public func addTokenToKeychain(token: Token) -> Token.KeychainItem? {
    guard let data = Token.URLSerializer.serialize(token)?.absoluteString.dataUsingEncoding(NSUTF8StringEncoding)
        else { return nil }

    let attributes = [
        kSecAttrGeneric as String:  data,
        kSecValueData as String:    token.generator.secret,
        kSecAttrService as String:  kOTPService,
    ]

    guard let persistentRef = addKeychainItemWithAttributes(attributes) else {
        return nil
    }
    return Token.KeychainItem(token: token, persistentRef: persistentRef)
}

public func updateKeychainItem(keychainItem: Token.KeychainItem, withToken token: Token) -> Token.KeychainItem? {
    guard let data = Token.URLSerializer.serialize(token)?.absoluteString.dataUsingEncoding(NSUTF8StringEncoding)
        else { return nil }

    let attributes = [
        kSecAttrGeneric as String:  data
    ]

    let success = updateKeychainItemForPersistentRef(keychainItem.persistentRef, withAttributes: attributes)
    guard success else {
        return nil
    }
    return Token.KeychainItem(token: token, persistentRef: keychainItem.persistentRef)
}

// After calling deleteKeychainItem(), the KeychainItem's keychainItemRef is no longer valid, and the keychain item should be discarded
public func deleteKeychainItem(keychainItem: Token.KeychainItem) -> Bool {
    return deleteKeychainItemForPersistentRef(keychainItem.persistentRef)
}
