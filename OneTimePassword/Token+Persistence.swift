//
//  Token+Persistence.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/9/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

extension Token {
    struct KeychainItem {
        let token: Token
        let keychainItemRef: NSData

        static func keychainItemForToken(token: Token) -> KeychainItem? {
            if let persistentRef = addKeychainItemWithURLAndSecret(token.url(), token.secret) {
                return KeychainItem(token: token, keychainItemRef: persistentRef)
            }
            return nil
        }

        static func keychainItemWithKeychainItemRef(keychainItemRef: NSData) -> KeychainItem? {
            if let result = keychainItemForPersistentRef(keychainItemRef) {
                return keychainItemWithDictionary(result)
            }
            return nil
        }

        static func keychainItemWithDictionary(keychainDictionary: NSDictionary) -> KeychainItem? {
            if let tuple = tupleWithKeychainDictionary(keychainDictionary) {
                if let token = Token.tokenWithURL(tuple.url, secret: tuple.secret) {
                    return KeychainItem(token: token, keychainItemRef: tuple.keychainItemRef)
                }
            }
            return nil
        }

        // After calling removeFromKeychain(), the KeychainItem's keychainItemRef is no longer valid, and the keychain item should be discarded
        func removeFromKeychain() -> Bool {
            return deleteKeychainItemForPersistentRef(self.keychainItemRef)
        }
    }
}
