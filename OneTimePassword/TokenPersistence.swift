//
//  TokenPersistence.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/9/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import Foundation

let kOTPService = "me.mattrubin.onetimepassword.token"

private extension Token {
    var keychainAttributes: NSDictionary? {
        guard let url = Token.URLSerializer.serialize(self),
            let data = url.absoluteString.dataUsingEncoding(NSUTF8StringEncoding) else {
                return nil
        }
        return [
            kSecAttrGeneric as String:  data,
            kSecValueData as String:    generator.secret,
            kSecAttrService as String:  kOTPService,
        ]
    }
}

private extension PersistentToken {
    private init?(keychainDictionary: NSDictionary) {
        guard let urlData = keychainDictionary[kSecAttrGeneric as String] as? NSData,
            let string = NSString(data: urlData, encoding:NSUTF8StringEncoding),
            let secret = keychainDictionary[kSecValueData as String] as? NSData,
            let keychainItemRef = keychainDictionary[kSecValuePersistentRef as String] as? NSData,
            let url = NSURL(string: string as String),
            let token = Token.URLSerializer.deserialize(url, secret: secret) else {
                return nil
        }
        self.init(token: token, identifier: keychainItemRef)
    }
}

public class Keychain {
    public static let sharedInstance = Keychain()

    public func persistentTokenWithIdentifier(identifier: NSData) -> PersistentToken? {
        guard let result = keychainItemForPersistentRef(identifier) else {
            return nil
        }
        return PersistentToken(keychainDictionary: result)
    }

    public func allPersistentTokens() -> [PersistentToken] {
        guard let keychainItems = allKeychainItems() else {
            return []
        }
        var tokens: [PersistentToken] = []
        for item: AnyObject in keychainItems {
            if let keychainDict = item as? NSDictionary,
                let persistentToken = PersistentToken(keychainDictionary: keychainDict) {
                    tokens.append(persistentToken)
            }
        }
        return tokens
    }

    public func addToken(token: Token) -> PersistentToken? {
        guard let attributes = token.keychainAttributes else {
            return nil
        }

        guard let persistentRef = addKeychainItemWithAttributes(attributes) else {
            return nil
        }
        return PersistentToken(token: token, identifier: persistentRef)
    }

    public func updatePersistentToken(persistentToken: PersistentToken, withToken token: Token) -> PersistentToken? {
        guard let attributes = token.keychainAttributes else {
            return nil
        }

        let success = updateKeychainItemForPersistentRef(persistentToken.identifier,
            withAttributes: attributes)
        guard success else {
            return nil
        }
        return PersistentToken(token: token, identifier: persistentToken.identifier)
    }

    // After calling deletePersistentToken(_:), the PersistentToken's identifier is no longer valid, and the token should be discarded
    public func deletePersistentToken(persistentToken: PersistentToken) -> Bool {
        return deleteKeychainItemForPersistentRef(persistentToken.identifier)
    }
}
