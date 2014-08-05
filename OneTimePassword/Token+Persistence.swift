//
//  Token+Persistence.swift
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
            let urlData = keychainDictionary[kSecAttrGeneric.takeUnretainedValue() as NSCopying] as? NSData
            let urlString: NSString? = NSString(data: urlData, encoding:NSUTF8StringEncoding)
            if let url = NSURL.URLWithString(urlString) {
                if let secret = keychainDictionary[kSecValueData.takeUnretainedValue() as NSCopying] as? NSData {
                    if let keychainItemRef = keychainDictionary[kSecValuePersistentRef.takeUnretainedValue() as NSCopying] as? NSData {
                        if let token = Token.tokenWithURL(url, secret: secret) {
                            return KeychainItem(token: token, persistentRef: keychainItemRef)
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

func _allKeychainItems() -> NSArray? {
    let queryDict = [
        kSecClass.takeUnretainedValue() as NSCopying: kSecClassGenericPassword.takeUnretainedValue() as NSCopying,
        kSecMatchLimit.takeUnretainedValue() as NSCopying: kSecMatchLimitAll.takeUnretainedValue() as NSCopying,
        kSecReturnPersistentRef.takeUnretainedValue() as NSCopying: kCFBooleanTrue,
        kSecReturnAttributes.takeUnretainedValue() as NSCopying: kCFBooleanTrue,
        kSecReturnData.takeUnretainedValue() as NSCopying: kCFBooleanTrue,
    ]

    var result: Unmanaged<AnyObject>?
    let resultCode = SecItemCopyMatching(queryDict, &result);

    if resultCode == OSStatus(errSecSuccess) {
        if let opaquePointer = result?.toOpaque() {
            return Unmanaged<NSArray>.fromOpaque(opaquePointer).takeUnretainedValue()
        }
    }
    return nil
}


public func addTokenToKeychain(token: Token) -> Token.KeychainItem? {
    var attributes = [
        kSecAttrGeneric.takeUnretainedValue() as NSCopying:
            token.url.absoluteString.dataUsingEncoding(NSUTF8StringEncoding) as NSCopying,
        kSecValueData.takeUnretainedValue() as NSCopying: token.secret,
        kSecAttrService.takeUnretainedValue() as NSCopying: kOTPService,
    ]

    if let persistentRef = addKeychainItemWithAttributes(attributes) {
        return Token.KeychainItem(token: token, persistentRef: persistentRef)
    }
    return nil
}

public func updateKeychainItemWithToken(keychainItem: Token.KeychainItem, token: Token) -> Token.KeychainItem?
{
    var attributes = [
        kSecAttrGeneric.takeUnretainedValue() as NSCopying:
            token.url.absoluteString.dataUsingEncoding(NSUTF8StringEncoding) as NSCopying
    ]

    if updateKeychainItemForPersistentRefWithAttributes(keychainItem.persistentRef, attributes) {
        return Token.KeychainItem(token: token, persistentRef: keychainItem.persistentRef)
    }
    return nil
}

// After calling deleteKeychainItem(), the KeychainItem's keychainItemRef is no longer valid, and the keychain item should be discarded
public func deleteKeychainItem(keychainItem: Token.KeychainItem) -> Bool {
    return deleteKeychainItemForPersistentRef(keychainItem.persistentRef)
}
