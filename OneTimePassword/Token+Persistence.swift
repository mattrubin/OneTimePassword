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
        let keychainItemRef: NSData

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

        // After calling removeFromKeychain(), the KeychainWrapper's keychainItemRef is no longer valid, and the wrapper should be discarded
        func removeFromKeychain() -> Bool {
            return deleteKeychainItemForPersistentRef(self.keychainItemRef)
        }
    }
}
