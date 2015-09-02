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

        public static func keychainItemWithKeychainItemRef(keychainItemRef: NSData) -> KeychainItem? {
            if let result = keychainItemForPersistentRef(keychainItemRef) {
                return keychainItemWithDictionary(result)
            }
            return nil
        }

        public static func keychainItemWithDictionary(keychainDictionary: NSDictionary) -> KeychainItem? {
            if let urlData = keychainDictionary[kSecAttrGeneric as! NSCopying] as? NSData {
                let urlString: NSString? = NSString(data: urlData, encoding:NSUTF8StringEncoding) // may return nil
                if let string = urlString {
                    if let secret = keychainDictionary[kSecValueData as! NSCopying] as? NSData {
                        if let keychainItemRef = keychainDictionary[kSecValuePersistentRef as! NSCopying] as? NSData {
                            if let token = Token.URLSerializer.deserialize(string as String, secret: secret) {
                                return KeychainItem(token: token, persistentRef: keychainItemRef)
                            }
                        }
                    }
                }
            }
            return nil
        }

        public static func allKeychainItems() -> Array<KeychainItem> {
            var items = Array<KeychainItem>()
            if let keychainItems = _allKeychainItems() {
                for item: AnyObject in keychainItems {
                    if let keychainDict = item as? NSDictionary {
                        if let keychainItem = keychainItemWithDictionary(keychainDict) {
                            items.append(keychainItem)
                        }
                    }
                }
            }
            return items
        }
    }
}

func keychainItemForPersistentRef(persistentRef: NSData) -> NSDictionary? {
    let queryDict = [
        kSecClass as! NSCopying: kSecClassGenericPassword,
        kSecValuePersistentRef as! NSCopying: persistentRef,
        kSecReturnPersistentRef as! NSCopying: kCFBooleanTrue,
        kSecReturnAttributes as! NSCopying: kCFBooleanTrue,
        kSecReturnData as! NSCopying: kCFBooleanTrue,
    ]

    var result: AnyObject?
    let resultCode = withUnsafeMutablePointer(&result) {
        SecItemCopyMatching(queryDict, $0)
    }

    if resultCode == OSStatus(errSecSuccess) {
        if let result = result {
            return result as? NSDictionary
        }
    }
    return nil
}

func _allKeychainItems() -> NSArray? {
    let queryDict = [
        kSecClass as! NSCopying: kSecClassGenericPassword,
        kSecMatchLimit as! NSCopying: kSecMatchLimitAll,
        kSecReturnPersistentRef as! NSCopying: kCFBooleanTrue,
        kSecReturnAttributes as! NSCopying: kCFBooleanTrue,
        kSecReturnData as! NSCopying: kCFBooleanTrue,
    ]

    var result: AnyObject?
    let resultCode = withUnsafeMutablePointer(&result) {
        SecItemCopyMatching(queryDict, $0)
    }

    if resultCode == OSStatus(errSecSuccess) {
        if let result = result {
            return result as? NSArray
        }
    }
    return nil
}


public func addTokenToKeychain(token: Token) -> Token.KeychainItem? {
    if let data = Token.URLSerializer.serialize(token)?.dataUsingEncoding(NSUTF8StringEncoding) {
        let attributes = [
            kSecAttrGeneric as! NSCopying: data,
            kSecValueData as! NSCopying: token.core.secret,
            kSecAttrService as! NSCopying: kOTPService,
        ]

        if let persistentRef = addKeychainItemWithAttributes(attributes) {
            return Token.KeychainItem(token: token, persistentRef: persistentRef)
        }
    }
    return nil
}

public func updateKeychainItemWithToken(keychainItem: Token.KeychainItem, token: Token) -> Token.KeychainItem? {
    if let data = Token.URLSerializer.serialize(token)?.dataUsingEncoding(NSUTF8StringEncoding) {
        let attributes = [kSecAttrGeneric as! NSCopying: data]

        if updateKeychainItemForPersistentRefWithAttributes(keychainItem.persistentRef, attributesToUpdate: attributes) {
            return Token.KeychainItem(token: token, persistentRef: keychainItem.persistentRef)
        }
    }
    return nil
}

// After calling deleteKeychainItem(), the KeychainItem's keychainItemRef is no longer valid, and the keychain item should be discarded
public func deleteKeychainItem(keychainItem: Token.KeychainItem) -> Bool {
    return deleteKeychainItemForPersistentRef(keychainItem.persistentRef)
}
