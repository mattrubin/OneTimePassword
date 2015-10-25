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
            guard let result = keychainItemForPersistentRef(keychainItemRef)
                else { return nil }
            return keychainItemWithDictionary(result)
        }

        public static func keychainItemWithDictionary(keychainDictionary: NSDictionary) -> KeychainItem? {
            guard let urlData = keychainDictionary[kSecAttrGeneric as! NSCopying] as? NSData,
                let string = NSString(data: urlData, encoding:NSUTF8StringEncoding),
                let secret = keychainDictionary[kSecValueData as! NSCopying] as? NSData,
                let keychainItemRef = keychainDictionary[kSecValuePersistentRef as! NSCopying] as? NSData,
                let token = Token.URLSerializer.deserialize(string as String, secret: secret)
                else { return nil }
            return KeychainItem(token: token, persistentRef: keychainItemRef)
        }

        public static func allKeychainItems() -> Array<KeychainItem> {
            guard let keychainItems = _allKeychainItems()
                else { return [] }

            var items = Array<KeychainItem>()
            for item: AnyObject in keychainItems {
                if let keychainDict = item as? NSDictionary,
                    let keychainItem = keychainItemWithDictionary(keychainDict) {
                        items.append(keychainItem)
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

    guard resultCode == OSStatus(errSecSuccess)
        else { return nil }

    return result as? NSDictionary
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

    guard resultCode == OSStatus(errSecSuccess)
        else { return nil }

    return result as? NSArray
}


public func addTokenToKeychain(token: Token) -> Token.KeychainItem? {
    guard let data = Token.URLSerializer.serialize(token)?.dataUsingEncoding(NSUTF8StringEncoding)
        else { return nil }

    let attributes = [
        kSecAttrGeneric as! NSCopying: data,
        kSecValueData as! NSCopying: token.core.secret,
        kSecAttrService as! NSCopying: kOTPService,
    ]

    guard let persistentRef = addKeychainItemWithAttributes(attributes)
        else { return nil }

    return Token.KeychainItem(token: token, persistentRef: persistentRef)
}

public func updateKeychainItem(keychainItem: Token.KeychainItem, withToken token: Token) -> Token.KeychainItem? {
    guard let data = Token.URLSerializer.serialize(token)?.dataUsingEncoding(NSUTF8StringEncoding)
        else { return nil }

    let attributes = [kSecAttrGeneric as! NSCopying: data]

    guard updateKeychainItemForPersistentRef(keychainItem.persistentRef, withAttributes: attributes)
        else { return nil }

    return Token.KeychainItem(token: token, persistentRef: keychainItem.persistentRef)
}

// After calling deleteKeychainItem(), the KeychainItem's keychainItemRef is no longer valid, and the keychain item should be discarded
public func deleteKeychainItem(keychainItem: Token.KeychainItem) -> Bool {
    return deleteKeychainItemForPersistentRef(keychainItem.persistentRef)
}
