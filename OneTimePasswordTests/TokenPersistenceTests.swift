//
//  TokenPersistenceTests.swift
//  OneTimePassword
//
//  Copyright (c) 2013-2015 OneTimePassword authors
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import XCTest
import OneTimePassword

let kValidSecret: [UInt8] = [ 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
    0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f ]

let kValidTokenURL = NSURL(string: "otpauth://totp/L%C3%A9on?algorithm=SHA256&digits=8&period=45&secret=AAAQEAYEAUDAOCAJBIFQYDIOB4")!

class TokenPersistenceTests: XCTestCase {
    let keychain = Keychain.sharedInstance

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
        guard let keychainItem = try? keychain.addToken(token) else {
            XCTFail("Failed to save token to keychain")
            return
        }

        // Restore the token
        do {
            guard let secondKeychainItem = try keychain.persistentTokenWithIdentifier(keychainItem.identifier) else {
                XCTFail("Failed to recover persistent token with identifier: \(keychainItem.identifier)")
                return
            }
            XCTAssertEqual(secondKeychainItem.token, keychainItem.token)
            XCTAssertEqual(secondKeychainItem.identifier, keychainItem.identifier)
        } catch {
            XCTFail("Error thrown from keychain: \(error)")
            return
        }

        // Modify the token
        let modifiedToken = Token(name: "???", issuer: "!", generator: token.generator.successor())

        do {
            let modifiedKeychainItem = try keychain.updatePersistentToken(keychainItem,
                withToken: modifiedToken)
            XCTAssertEqual(modifiedKeychainItem.identifier, keychainItem.identifier)
            XCTAssertEqual(modifiedKeychainItem.token, modifiedToken)
        } catch {
            XCTFail("Failed to update keychain with modified token")
            return
        }

        // Fetch the token again
        do {
            guard let thirdKeychainItem = try keychain.persistentTokenWithIdentifier(keychainItem.identifier) else {
                XCTFail("Failed to recover persistent token with identifier: \(keychainItem.identifier)")
                return
            }
            XCTAssertEqual(thirdKeychainItem.token, modifiedToken)
            XCTAssertEqual(thirdKeychainItem.identifier, keychainItem.identifier)
        } catch {
            XCTFail("Error thrown from keychain: \(error)")
            return
        }

        // Remove the token
        do {
            try keychain.deletePersistentToken(keychainItem)
        } catch {
            XCTFail("deletePersistentToken(_:) failed with error: \(error)")
        }

        // Attempt to restore the deleted token
        do {
            let fourthKeychainItem = try keychain.persistentTokenWithIdentifier(keychainItem.identifier)
            XCTAssertNil(fourthKeychainItem)
        } catch {
            XCTFail("Error thrown from keychain: \(error)")
            return
        }
    }

    func testDuplicateURLs() {
    do {
        guard let token1 = Token.URLSerializer.deserialize(kValidTokenURL),
            let token2 = Token.URLSerializer.deserialize(kValidTokenURL) else {
                XCTFail("Failed to construct tokens from url.")
                return
        }

        // Add both tokens to the keychain
        let savedItem1 = try keychain.addToken(token1)
        let savedItem2 = try keychain.addToken(token2)
        XCTAssertEqual(savedItem1.token, token1)
        XCTAssertEqual(savedItem2.token, token2)

        // Fetch both tokens from the keychain
        guard let fetchedItem1 = try keychain.persistentTokenWithIdentifier(savedItem1.identifier) else {
            XCTFail("Token should be in keychain: \(token1)")
            return
        }
        guard let fetchedItem2 = try keychain.persistentTokenWithIdentifier(savedItem2.identifier) else {
            XCTFail("Token should be in keychain: \(token2)")
            return
        }
        XCTAssertEqual(savedItem1, fetchedItem1)
        XCTAssertEqual(savedItem2, fetchedItem2)

        // Remove the first token from the keychain
        do {
            try keychain.deletePersistentToken(savedItem1)
        } catch {
            XCTFail("deletePersistentToken(_:) failed with error: \(error)")
        }

        let checkItem1 = try keychain.persistentTokenWithIdentifier(savedItem1.identifier)
        XCTAssertNil(checkItem1, "Token should not be in keychain: \(token1)")
        let checkItem2 = try keychain.persistentTokenWithIdentifier(savedItem2.identifier)
        XCTAssertNotNil(checkItem2, "Token should be in keychain: \(token2)")

        // Remove the second token from the keychain
        do {
            try keychain.deletePersistentToken(savedItem2)
        } catch {
            XCTFail("deletePersistentToken(_:) failed with error: \(error)")
        }

        let recheckItem1 = try keychain.persistentTokenWithIdentifier(savedItem1.identifier)
        XCTAssertNil(recheckItem1, "Token should not be in keychain: \(token1)")
        let recheckItem2 = try keychain.persistentTokenWithIdentifier(savedItem2.identifier)
        XCTAssertNil(recheckItem2, "Token should not be in keychain: \(token2)")

        // Try to remove both tokens from the keychain again
        do {
            try keychain.deletePersistentToken(savedItem1)
            // The deletion should throw and this line should never be reached.
            XCTFail("Removing again should fail: \(token1)")
        } catch {
            // TODO: Assert the expected error type
        }
        do {
            try keychain.deletePersistentToken(savedItem2)
            // The deletion should throw and this line should never be reached.
            XCTFail("Removing again should fail: \(token2)")
        } catch {
            // TODO: Assert the expected error type
        }

    } catch {
        XCTFail("Error thrown from keychain: \(error)")
        return
    }
    }

    func itemFromArray(items: [PersistentToken], withPersistentRef persistentRef: NSData) -> PersistentToken? {
        let matchingItems = items.filter({ $0.identifier == persistentRef })
        XCTAssert((matchingItems.count <= 1),
            "Found more than one matching token: \(matchingItems)")
        return matchingItems.first
    }

    func testAllTokensInKeychain() {
    do {
        guard let token1 = Token.URLSerializer.deserialize(kValidTokenURL),
            let token2 = Token.URLSerializer.deserialize(kValidTokenURL),
            let token3 = Token.URLSerializer.deserialize(kValidTokenURL) else {
                XCTFail("Failed to construct tokens from URL")
                return
        }

        let noItems = try keychain.allPersistentTokens()
        XCTAssert(noItems.isEmpty, "Array should be empty: \(noItems)")

        let savedItem1 = try keychain.addToken(token1)
        let savedItem2 = try keychain.addToken(token2)
        let savedItem3 = try keychain.addToken(token3)

        let allItems = try keychain.allPersistentTokens()

        XCTAssertNotNil(itemFromArray(allItems, withPersistentRef: savedItem1.identifier),
            "Token not recovered from keychain: \(token1)")
        XCTAssertNotNil(itemFromArray(allItems, withPersistentRef: savedItem2.identifier),
            "Token not recovered from keychain: \(token2)")
        XCTAssertNotNil(itemFromArray(allItems, withPersistentRef: savedItem3.identifier),
            "Token not recovered from keychain: \(token3)")

        do {
            try keychain.deletePersistentToken(savedItem1)
            try keychain.deletePersistentToken(savedItem2)
            try keychain.deletePersistentToken(savedItem3)
        } catch {
            XCTFail("deletePersistentToken(_:) failed with error: \(error)")
            return
        }

        let itemsRemaining = try keychain.allPersistentTokens()

        XCTAssertNil(itemFromArray(itemsRemaining, withPersistentRef: savedItem1.identifier),
            "Token not removed from keychain: \(token1)")
        XCTAssertNil(itemFromArray(itemsRemaining, withPersistentRef: savedItem2.identifier),
            "Token not removed from keychain: \(token2)")
        XCTAssertNil(itemFromArray(itemsRemaining, withPersistentRef: savedItem3.identifier),
            "Token not removed from keychain: \(token3)")
    } catch {
        XCTFail("Error thrown from keychain: \(error)")
        return
    }
    }
}
