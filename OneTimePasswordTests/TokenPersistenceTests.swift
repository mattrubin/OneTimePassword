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
let kToken = Token.URLSerializer.deserialize(kValidTokenURL)!

class TokenPersistenceTests: XCTestCase {
    let keychain = Keychain.sharedInstance

    func testTokenWithKeychainItemRef() {
        // Create a token
        let token = kToken

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
            XCTAssertEqual(secondKeychainItem, keychainItem)
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
        let token1 = kToken, token2 = kToken

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
            // An error thrown is the expected outcome
        }
        do {
            try keychain.deletePersistentToken(savedItem2)
            // The deletion should throw and this line should never be reached.
            XCTFail("Removing again should fail: \(token2)")
        } catch {
            // An error thrown is the expected outcome
        }
    }

    func testAllPersistentTokens() {
        let token1 = kToken, token2 = kToken, token3 = kToken

        do {
            let noTokens = try keychain.allPersistentTokens()
            XCTAssert(noTokens.isEmpty, "Expected no tokens in keychain: \(noTokens)")
        } catch {
            XCTFail("allPersistentTokens() failed with error: \(error)")
            return
        }

        do {
            let persistentToken1 = try keychain.addToken(token1)
            let persistentToken2 = try keychain.addToken(token2)
            let persistentToken3 = try keychain.addToken(token3)

            do {
                let allTokens = try keychain.allPersistentTokens()
                XCTAssertEqual(allTokens, [persistentToken1, persistentToken2, persistentToken3],
                    "Tokens not correctly recovered from keychain")
            } catch {
                XCTFail("allPersistentTokens() failed with error: \(error)")
                return
            }

            do {
                try keychain.deletePersistentToken(persistentToken1)
                try keychain.deletePersistentToken(persistentToken2)
                try keychain.deletePersistentToken(persistentToken3)
            } catch {
                XCTFail("deletePersistentToken(_:) failed with error: \(error)")
                return
            }

            do {
                let tokensRemaining = try keychain.allPersistentTokens()
                XCTAssert(tokensRemaining.isEmpty, "Expected no tokens in keychain: \(tokensRemaining)")
            } catch {
                XCTFail("allPersistentTokens() failed with error: \(error)")
                return
            }
        } catch {
            XCTFail("addToken(_:) failed with error: \(error)")
            return
        }
    }
}
