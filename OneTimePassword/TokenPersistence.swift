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

        private init(token: Token, persistentRef: NSData) {
            self.token = token
            self.persistentRef = persistentRef
        }

        // FIXME: This should be private, but is public for testing purposes
        public init?(keychainDictionary: NSDictionary) {
            guard let urlData = keychainDictionary[kSecAttrGeneric as String] as? NSData,
                let string = NSString(data: urlData, encoding:NSUTF8StringEncoding),
                let secret = keychainDictionary[kSecValueData as String] as? NSData,
                let keychainItemRef = keychainDictionary[kSecValuePersistentRef as String] as? NSData,
                let url = NSURL(string: string as String),
                let token = Token.URLSerializer.deserialize(url, secret: secret) else {
                    return nil
            }
            self.init(token: token, persistentRef: keychainItemRef)
        }
    }
}

extension Token.KeychainItem: Equatable {}
public func == (lhs: Token.KeychainItem, rhs: Token.KeychainItem) -> Bool {
    return lhs.persistentRef.isEqualToData(rhs.persistentRef)
        && (lhs.token == rhs.token)
}

public extension Keychain {
    public func keychainItemForPersistentRef(persistentRef: NSData) -> Token.KeychainItem? {
        guard let result = itemForPersistentRef(persistentRef) else {
            return nil
        }
        return Token.KeychainItem(keychainDictionary: result)
    }

    public func allKeychainItems() -> [Token.KeychainItem] {
        guard let keychainItems = Keychain.sharedInstance.allItems() else {
            return []
        }
        var items: [Token.KeychainItem] = []
        for item: AnyObject in keychainItems {
            if let keychainDict = item as? NSDictionary,
                let keychainItem = Token.KeychainItem(keychainDictionary: keychainDict) {
                    items.append(keychainItem)
            }
        }
        return items
    }

    public func addToken(token: Token) -> Token.KeychainItem? {
        guard let url = Token.URLSerializer.serialize(token),
            let data = url.absoluteString.dataUsingEncoding(NSUTF8StringEncoding) else {
                return nil
        }

        let attributes = [
            kSecAttrGeneric as String:  data,
            kSecValueData as String:    token.generator.secret,
            kSecAttrService as String:  kOTPService,
        ]

        guard let persistentRef = addItemWithAttributes(attributes) else {
            return nil
        }
        return Token.KeychainItem(token: token, persistentRef: persistentRef)
    }

    public func updateKeychainItem(keychainItem: Token.KeychainItem, withToken token: Token) -> Token.KeychainItem? {
        guard let url = Token.URLSerializer.serialize(token),
            let data = url.absoluteString.dataUsingEncoding(NSUTF8StringEncoding) else {
                return nil
        }

        let attributes = [
            kSecAttrGeneric as String:  data
        ]

        let success = updateItemForPersistentRef(keychainItem.persistentRef,
            withAttributes: attributes)
        guard success else {
            return nil
        }
        return Token.KeychainItem(token: token, persistentRef: keychainItem.persistentRef)
    }

    // After calling deleteKeychainItem(), the KeychainItem's keychainItemRef is no longer valid, and the keychain item should be discarded
    public func deleteKeychainItem(keychainItem: Token.KeychainItem) -> Bool {
        return deleteItemForPersistentRef(keychainItem.persistentRef)
    }
}
