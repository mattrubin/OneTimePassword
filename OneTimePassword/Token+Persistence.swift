//
//  Token+Persistence.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/9/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import Foundation

let kOTPService = "me.mattrubin.onetimepassword.token"

extension Token {
    struct KeychainItem {
        let token: Token
        let keychainItemRef: NSData

        static func keychainItemWithKeychainItemRef(keychainItemRef: NSData) -> KeychainItem? {
            if let result = keychainItemForPersistentRef(keychainItemRef) {
                return keychainItemWithDictionary(result)
            }
            return nil
        }

        static func keychainItemWithDictionary(keychainDictionary: NSDictionary) -> KeychainItem? {
            let urlData = keychainDictionary.objectForKey(_kSecAttrGeneric()) as? NSData
            let urlString: NSString? = NSString(data: urlData, encoding:NSUTF8StringEncoding)
            if let url = NSURL.URLWithString(urlString) {
                if let secret = keychainDictionary.objectForKey(_kSecValueData()) as? NSData {
                    if let keychainItemRef = keychainDictionary.objectForKey(_kSecValuePersistentRef()) as? NSData {
                        if let token = Token.tokenWithURL(url, secret: secret) {
                            return KeychainItem(token: token, keychainItemRef: keychainItemRef)
                        }
                    }
                }
            }
            return nil
        }

        static func allKeychainItems() -> Array<KeychainItem> {
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

func addTokenToKeychain(token: Token) -> Token.KeychainItem? {
    var attributes = NSMutableDictionary()
    attributes.setObject(token.url.absoluteString.dataUsingEncoding(NSUTF8StringEncoding), forKey: _kSecAttrGeneric() as NSCopying)
    attributes.setObject(token.secret, forKey: _kSecValueData() as NSCopying)
    attributes.setObject(kOTPService, forKey: _kSecAttrService() as NSCopying)

    if let persistentRef = addKeychainItemWithAttributes(attributes) {
        return Token.KeychainItem(token: token, keychainItemRef: persistentRef)
    }
    return nil
}

func updateKeychainItemWithToken(keychainItem: Token.KeychainItem, token: Token) -> Token.KeychainItem?
{
    var attributes = NSMutableDictionary()
    attributes.setObject(token.url.absoluteString.dataUsingEncoding(NSUTF8StringEncoding), forKey: _kSecAttrGeneric() as NSCopying)
    if updateKeychainItemForPersistentRefWithAttributes(keychainItem.keychainItemRef, attributes) {
        return Token.KeychainItem(token: token, keychainItemRef: keychainItem.keychainItemRef)
    }
    return nil
}

// After calling deleteKeychainItem(), the KeychainItem's keychainItemRef is no longer valid, and the keychain item should be discarded
func deleteKeychainItem(keychainItem: Token.KeychainItem) -> Bool {
    return deleteKeychainItemForPersistentRef(keychainItem.keychainItemRef)
}

