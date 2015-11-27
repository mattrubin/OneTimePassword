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
            XCTFail("persistentTokenWithIdentifier(_:) failed with error: \(error)")
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
            XCTFail("updatePersistentToken(_:withToken:) failed with error: \(error)")
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
            XCTFail("persistentTokenWithIdentifier(_:) failed with error: \(error)")
            return
        }

        // Remove the token
        do {
            try keychain.deletePersistentToken(keychainItem)
        } catch {
            XCTFail("deletePersistentToken(_:) failed with error: \(error)")
            return
        }

        // Attempt to restore the deleted token
        do {
            let fourthKeychainItem = try keychain.persistentTokenWithIdentifier(keychainItem.identifier)
            XCTAssertNil(fourthKeychainItem)
        } catch {
            XCTFail("persistentTokenWithIdentifier(_:) failed with error: \(error)")
            return
        }
    }

    func testDuplicateURLs() {
        guard let token1 = Token.URLSerializer.deserialize(kValidTokenURL),
            let token2 = Token.URLSerializer.deserialize(kValidTokenURL) else {
                XCTFail("Failed to construct tokens from url.")
                return
        }

        // Add both tokens to the keychain
        guard let savedItem1 = try? keychain.addToken(token1) else {
            XCTFail("Failed to save to keychain: \(token1)")
            return
        }
        guard let savedItem2 = try? keychain.addToken(token2) else {
            XCTFail("Failed to save to keychain: \(token2)")
            return
        }
        XCTAssertEqual(savedItem1.token, token1)
        XCTAssertEqual(savedItem2.token, token2)

        // Fetch both tokens from the keychain
        do {
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
        } catch {
            XCTFail("persistentTokenWithIdentifier(_:) failed with error: \(error)")
            return
        }

        // Remove the first token from the keychain
        do {
            try keychain.deletePersistentToken(savedItem1)
        } catch {
            XCTFail("deletePersistentToken(_:) failed with error: \(error)")
            return
        }

        do {
            let checkItem1 = try keychain.persistentTokenWithIdentifier(savedItem1.identifier)
            XCTAssertNil(checkItem1, "Token should not be in keychain: \(token1)")
            let checkItem2 = try keychain.persistentTokenWithIdentifier(savedItem2.identifier)
            XCTAssertNotNil(checkItem2, "Token should be in keychain: \(token2)")
        } catch {
            XCTFail("persistentTokenWithIdentifier(_:) failed with error: \(error)")
            return
        }

        // Remove the second token from the keychain
        do {
            try keychain.deletePersistentToken(savedItem2)
        } catch {
            XCTFail("deletePersistentToken(_:) failed with error: \(error)")
            return
        }

        do {
            let recheckItem1 = try keychain.persistentTokenWithIdentifier(savedItem1.identifier)
            XCTAssertNil(recheckItem1, "Token should not be in keychain: \(token1)")
            let recheckItem2 = try keychain.persistentTokenWithIdentifier(savedItem2.identifier)
            XCTAssertNil(recheckItem2, "Token should not be in keychain: \(token2)")
        } catch {
            XCTFail("persistentTokenWithIdentifier(_:) failed with error: \(error)")
            return
        }

        // Try to remove both tokens from the keychain again
        do {
            try keychain.deletePersistentToken(savedItem1)
            // The deletion should throw and this line should never be reached.
            XCTFail("Removing again should fail: \(token1)")
        } catch {
            // This is the expected outcome
            // TODO: Assert the expected error type
        }
        do {
            try keychain.deletePersistentToken(savedItem2)
            // The deletion should throw and this line should never be reached.
            XCTFail("Removing again should fail: \(token2)")
        } catch {
            // This is the expected outcome
            // TODO: Assert the expected error type
        }
    }

    func itemFromArray(items: [PersistentToken], withPersistentRef persistentRef: NSData) -> PersistentToken? {
        let matchingItems = items.filter({ $0.identifier == persistentRef })
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

        do {
            let noItems = try keychain.allPersistentTokens()
            XCTAssert(noItems.isEmpty, "Array should be empty: \(noItems)")
        } catch {
            XCTFail("allPersistentTokens() failed with error: \(error)")
            return
        }

        guard let savedItem1 = try? keychain.addToken(token1),
            let savedItem2 = try? keychain.addToken(token2),
            let savedItem3 = try? keychain.addToken(token3) else {
                XCTFail("Failed to save tokens")
                return
        }

        do {
            let allItems = try keychain.allPersistentTokens()
            XCTAssertNotNil(itemFromArray(allItems, withPersistentRef: savedItem1.identifier),
                "Token not recovered from keychain: \(token1)")
            XCTAssertNotNil(itemFromArray(allItems, withPersistentRef: savedItem2.identifier),
                "Token not recovered from keychain: \(token2)")
            XCTAssertNotNil(itemFromArray(allItems, withPersistentRef: savedItem3.identifier),
                "Token not recovered from keychain: \(token3)")
        } catch {
            XCTFail("allPersistentTokens() failed with error: \(error)")
            return
        }

        do {
            try keychain.deletePersistentToken(savedItem1)
            try keychain.deletePersistentToken(savedItem2)
            try keychain.deletePersistentToken(savedItem3)
        } catch {
            XCTFail("deletePersistentToken(_:) failed with error: \(error)")
            return
        }

        do {
            let itemsRemaining = try keychain.allPersistentTokens()
            XCTAssert(itemsRemaining.isEmpty, "Array should be empty: \(itemsRemaining)")
        } catch {
            XCTFail("allPersistentTokens() failed with error: \(error)")
            return
        }
    }
}
