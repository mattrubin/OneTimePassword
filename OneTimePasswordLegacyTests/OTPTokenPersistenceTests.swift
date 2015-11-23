//
//  OTPTokenPersistenceTests.swift
//  OneTimePassword
//
//  Copyright (c) 2013 Matt Rubin
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import XCTest
import OneTimePassword

let kValidSecret: [UInt8] = [ 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
    0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f ]

let kValidTokenURL = NSURL(string: "otpauth://totp/L%C3%A9on?algorithm=SHA256&digits=8&period=45&secret=AAAQEAYEAUDAOCAJBIFQYDIOB4")!

class OTPTokenPersistenceTests: XCTestCase {
    func testTokenWithKeychainItemRef() {
        // Create a token
        guard let token = Token.URLSerializer.deserialize(kValidTokenURL) else {
            XCTFail("Failed to construct token from url")
            return
        }

        XCTAssertEqual(token.name, "Léon")
        XCTAssertEqual(token.issuer, "")
        XCTAssertEqual(token.generator.factor, Generator.Factor.Timer(period: 45))
        XCTAssertEqual(token.generator.algorithm, Generator.Algorithm.SHA256)
        XCTAssertEqual(token.generator.digits, 8)
        XCTAssertEqual(token.generator.secret, NSData(bytes: kValidSecret, length: kValidSecret.count))

        // Save the token
        guard let keychainItem = Keychain.sharedInstance.addToken(token) else {
            XCTFail("Failed to save token to keychain")
            return
        }

        // Restore the token
        guard let secondKeychainItem = Keychain.sharedInstance.tokenItemForPersistentRef(keychainItem.persistentRef) else {
                XCTFail("Failed to recover keychain item for persistent ref")
                return
        }
        XCTAssertEqual(secondKeychainItem.token, keychainItem.token)
        XCTAssertEqual(secondKeychainItem.persistentRef, keychainItem.persistentRef)

        // Modify the token
        let modifiedToken = Token(name: "???", issuer: "!", generator: token.generator.successor())

        guard let modifiedKeychainItem = Keychain.sharedInstance.updateTokenItem(keychainItem,
            withToken: modifiedToken) else {
                XCTFail("Failed to update keychain with modified token")
                return
        }
        XCTAssertEqual(modifiedKeychainItem.persistentRef, keychainItem.persistentRef)
        XCTAssertEqual(modifiedKeychainItem.token, modifiedToken)

        // Fetch the token again
        guard let thirdKeychainItem = Keychain.sharedInstance.tokenItemForPersistentRef(keychainItem.persistentRef) else {
            XCTFail("Failed to recover keychain item for persistent ref")
            return
        }
        XCTAssertEqual(thirdKeychainItem.token, modifiedToken);
        XCTAssertEqual(thirdKeychainItem.persistentRef, keychainItem.persistentRef)

        // Remove the token
        let success = Keychain.sharedInstance.deleteTokenItem(keychainItem)
        XCTAssertTrue(success)

        // Attempt to restore the deleted token
        let fourthKeychainItem = Keychain.sharedInstance.tokenItemForPersistentRef(keychainItem.persistentRef)
        XCTAssertNil(fourthKeychainItem)
    }

    func testDuplicateURLs() {
        guard let token1 = Token.URLSerializer.deserialize(kValidTokenURL),
            let token2 = Token.URLSerializer.deserialize(kValidTokenURL) else {
                XCTFail("Failed to construct tokens from url.")
                return
        }

        // Add both tokens to the keychain
        guard let savedItem1 = Keychain.sharedInstance.addToken(token1) else {
            XCTFail("Failed to save to keychain: \(token1)")
            return
        }
        guard let savedItem2 = Keychain.sharedInstance.addToken(token2) else {
            XCTFail("Failed to save to keychain: \(token2)")
            return
        }
        XCTAssertEqual(savedItem1.token, token1)
        XCTAssertEqual(savedItem2.token, token2)

        // Fetch both tokens from the keychain
        guard let fetchedItem1 = Keychain.sharedInstance.tokenItemForPersistentRef(savedItem1.persistentRef) else {
            XCTFail("Token should be in keychain: \(token1)")
            return
        }
        guard let fetchedItem2 = Keychain.sharedInstance.tokenItemForPersistentRef(savedItem2.persistentRef) else {
            XCTFail("Token should be in keychain: \(token2)")
            return
        }
        XCTAssertEqual(savedItem1, fetchedItem1)
        XCTAssertEqual(savedItem2, fetchedItem2)

        // Remove the first token from the keychain
        let delete1success = Keychain.sharedInstance.deleteTokenItem(savedItem1)
        XCTAssertTrue(delete1success, "Failed to remove from keychain: \(token1)")

        let checkItem1 = Keychain.sharedInstance.tokenItemForPersistentRef(savedItem1.persistentRef)
        XCTAssertNil(checkItem1, "Token should not be in keychain: \(token1)")
        let checkItem2 = Keychain.sharedInstance.tokenItemForPersistentRef(savedItem2.persistentRef)
        XCTAssertNotNil(checkItem2, "Token should be in keychain: \(token2)")

        // Remove the second token from the keychain
        let delete2success = Keychain.sharedInstance.deleteTokenItem(savedItem2)
        XCTAssertTrue(delete2success, "Failed to remove from keychain: \(token2)")

        let recheckItem1 = Keychain.sharedInstance.tokenItemForPersistentRef(savedItem1.persistentRef)
        XCTAssertNil(recheckItem1, "Token should not be in keychain: \(token1)")
        let recheckItem2 = Keychain.sharedInstance.tokenItemForPersistentRef(savedItem2.persistentRef)
        XCTAssertNil(recheckItem2, "Token should not be in keychain: \(token2)")

        // Try to remove both tokens from the keychain again
        let redelete1success = Keychain.sharedInstance.deleteTokenItem(savedItem1)
        XCTAssertFalse(redelete1success, "Removing again should fail: \(token1)")
        let redelete2success = Keychain.sharedInstance.deleteTokenItem(savedItem2)
        XCTAssertFalse(redelete2success, "Removing again should fail: \(token2)")
    }

    func itemFromArray(items: [Keychain.TokenItem], withPersistentRef persistentRef: NSData) -> Keychain.TokenItem? {
        let matchingItems = items.filter({ $0.persistentRef == persistentRef })
        XCTAssert((matchingItems.count <= 1),
            "Found more than one matching token: \(matchingItems)")
        return matchingItems.first
    }

    func testAllTokensInKeychain() {
        guard let token1 = Token.URLSerializer.deserialize(kValidTokenURL),
            let token2 = Token.URLSerializer.deserialize(kValidTokenURL),
            let token3 = Token.URLSerializer.deserialize(kValidTokenURL) else {
                XCTFail("Failed to construct tokens from URL")
                return
        }

        guard let savedItem1 = Keychain.sharedInstance.addToken(token1),
            let savedItem2 = Keychain.sharedInstance.addToken(token2),
            let savedItem3 = Keychain.sharedInstance.addToken(token3) else {
                XCTFail("Failed to save tokens")
                return
        }

        let allItems = Keychain.sharedInstance.allTokenItems()

        XCTAssertNotNil(itemFromArray(allItems, withPersistentRef: savedItem1.persistentRef),
            "Token not recovered from keychain: \(token1)")
        XCTAssertNotNil(itemFromArray(allItems, withPersistentRef: savedItem2.persistentRef),
            "Token not recovered from keychain: \(token2)")
        XCTAssertNotNil(itemFromArray(allItems, withPersistentRef: savedItem3.persistentRef),
            "Token not recovered from keychain: \(token3)")

        guard Keychain.sharedInstance.deleteTokenItem(savedItem1) &&
            Keychain.sharedInstance.deleteTokenItem(savedItem2) &&
            Keychain.sharedInstance.deleteTokenItem(savedItem3) else {
                XCTFail("Failed to delete tokens")
                return
        }

        let itemsRemaining = Keychain.sharedInstance.allTokenItems()

        XCTAssertNil(itemFromArray(itemsRemaining, withPersistentRef: savedItem1.persistentRef),
            "Token not removed from keychain: \(token1)")
        XCTAssertNil(itemFromArray(itemsRemaining, withPersistentRef: savedItem2.persistentRef),
            "Token not removed from keychain: \(token2)")
        XCTAssertNil(itemFromArray(itemsRemaining, withPersistentRef: savedItem3.persistentRef),
            "Token not removed from keychain: \(token3)")
    }
}
