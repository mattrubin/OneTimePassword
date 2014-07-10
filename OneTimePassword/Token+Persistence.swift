//
//  Token+Persistence.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/9/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

extension Token {
    class KeychainWrapper {
        let token: Token
        var keychainItemRef: NSData? // TODO: make this a required constant

        init(token: Token, keychainItemRef: NSData) {
            self.token = token
            self.keychainItemRef = keychainItemRef
        }

        class func wrapperForToken(token: Token) -> KeychainWrapper? {
            if let persistentRef = addKeychainItemWithURLAndSecret(token.url(), token.secret) {
                return Token.KeychainWrapper(token: token, keychainItemRef: persistentRef)
            }
            return nil
        }

        func removeFromKeychain() -> Bool {
            if (!self.keychainItemRef) { return false }

            let success = deleteKeychainItemForPersistentRef(self.keychainItemRef)
            if (success) { self.keychainItemRef = nil}

            return success;
        }
    }
}
