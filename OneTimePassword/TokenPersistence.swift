//
//  TokenPersistence.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/9/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import Foundation

let kOTPService = "me.mattrubin.onetimepassword.token"

public extension Keychain {
    public struct TokenItem {
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

extension Keychain.TokenItem: Equatable {}
public func == (lhs: Keychain.TokenItem, rhs: Keychain.TokenItem) -> Bool {
    return lhs.persistentRef.isEqualToData(rhs.persistentRef)
        && (lhs.token == rhs.token)
}

public extension Keychain {
    // FIXME: remove this function
    public func tokenItemForPersistentRef(persistentRef: NSData) -> TokenItem? {
        guard let result = itemForPersistentRef(persistentRef) else {
            return nil
        }
        return TokenItem(keychainDictionary: result)
    }

    public func allTokenItems() -> [TokenItem] {
        guard let keychainItems = Keychain.sharedInstance.allItems() else {
            return []
        }
        var items: [TokenItem] = []
        for item: AnyObject in keychainItems {
            if let keychainDict = item as? NSDictionary,
                let tokenItem = TokenItem(keychainDictionary: keychainDict) {
                    items.append(tokenItem)
            }
        }
        return items
    }

    public func addToken(token: Token) -> TokenItem? {
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
        return TokenItem(token: token, persistentRef: persistentRef)
    }

    public func updateTokenItem(tokenItem: TokenItem, withToken token: Token) -> TokenItem? {
        guard let url = Token.URLSerializer.serialize(token),
            let data = url.absoluteString.dataUsingEncoding(NSUTF8StringEncoding) else {
                return nil
        }

        let attributes = [
            kSecAttrGeneric as String:  data
        ]

        let success = updateItemForPersistentRef(tokenItem.persistentRef,
            withAttributes: attributes)
        guard success else {
            return nil
        }
        return TokenItem(token: token, persistentRef: tokenItem.persistentRef)
    }

    // After calling deleteTokenItem(), the TokenItem's persistentRef is no longer valid, and the token item should be discarded
    public func deleteTokenItem(tokenItem: TokenItem) -> Bool {
        return deleteItemForPersistentRef(tokenItem.persistentRef)
    }
}
