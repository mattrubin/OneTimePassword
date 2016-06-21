//
//  KeychainTests.swift
//  OneTimePassword
//
//  Copyright (c) 2013-2015 Matt Rubin and the OneTimePassword authors
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

let testToken = Token(
    name: "Name",
    issuer: "Issuer",
    generator: Generator(
        factor: .timer(period: 45),
        secret: Data(base32String: "AAAQEAYEAUDAOCAJBIFQYDIOB4"),
        algorithm: .SHA256,
        digits: 8
    )!
)

class KeychainTests: XCTestCase {
    let keychain = Keychain.sharedInstance

    func testPersistentTokenWithIdentifier() {
        // Create a token
        let token = testToken

        do {
            // Save the token
            let savedToken = try keychain.addToken(token)

            // Restore the token
            do {
                let fetchedToken = try keychain.persistentTokenWithIdentifier(savedToken.identifier)
                XCTAssertEqual(fetchedToken, savedToken, "Token should have been saved to keychain")
            } catch {
                XCTFail("persistentTokenWithIdentifier(_:) failed with error: \(error)")
            }

            // Modify the token
            let modifiedToken = Token(
                name: "New Name",
                issuer: "New Issuer",
                generator: token.generator.successor()
            )
            do {
                let updatedToken = try keychain.updatePersistentToken(savedToken,
                    withToken: modifiedToken)
                XCTAssertEqual(updatedToken.identifier, savedToken.identifier)
                XCTAssertEqual(updatedToken.token, modifiedToken)
            } catch {
                XCTFail("updatePersistentToken(_:withToken:) failed with error: \(error)")
            }

            // Fetch the token again
            do {
                let fetchedToken = try keychain.persistentTokenWithIdentifier(savedToken.identifier)
                XCTAssertEqual(fetchedToken?.token, modifiedToken)
                XCTAssertEqual(fetchedToken?.identifier, savedToken.identifier)
            } catch {
                XCTFail("persistentTokenWithIdentifier(_:) failed with error: \(error)")
            }

            // Remove the token
            do {
                try keychain.deletePersistentToken(savedToken)
            } catch {
                XCTFail("deletePersistentToken(_:) failed with error: \(error)")
            }

            // Attempt to restore the deleted token
            do {
                let fetchedToken = try keychain.persistentTokenWithIdentifier(savedToken.identifier)
                XCTAssertNil(fetchedToken, "Token should have been removed from keychain")
            } catch {
                XCTFail("persistentTokenWithIdentifier(_:) failed with error: \(error)")
            }
        } catch {
            XCTFail("addToken(_:) failed with error: \(error)")
        }
    }

    func testDuplicateTokens() {
        let token1 = testToken, token2 = testToken

        do {
            // Add both tokens to the keychain
            let savedItem1 = try keychain.addToken(token1)
            let savedItem2 = try keychain.addToken(token2)
            XCTAssertEqual(savedItem1.token, token1)
            XCTAssertEqual(savedItem2.token, token2)

            // Fetch both tokens from the keychain
            do {
                let fetchedItem1 = try keychain.persistentTokenWithIdentifier(savedItem1.identifier)
                let fetchedItem2 = try keychain.persistentTokenWithIdentifier(savedItem2.identifier)
                XCTAssertEqual(fetchedItem1, savedItem1, "Saved token not found in keychain")
                XCTAssertEqual(fetchedItem2, savedItem2, "Saved token not found in keychain")
            } catch {
                XCTFail("persistentTokenWithIdentifier(_:) failed with error: \(error)")
            }

            // Remove the first token from the keychain
            do {
                try keychain.deletePersistentToken(savedItem1)
            } catch {
                XCTFail("deletePersistentToken(_:) failed with error: \(error)")
            }

            do {
                let checkItem1 = try keychain.persistentTokenWithIdentifier(savedItem1.identifier)
                let checkItem2 = try keychain.persistentTokenWithIdentifier(savedItem2.identifier)
                XCTAssertNil(checkItem1, "Token should not be in keychain: \(token1)")
                XCTAssertNotNil(checkItem2, "Token should be in keychain: \(token2)")
            } catch {
                XCTFail("persistentTokenWithIdentifier(_:) failed with error: \(error)")
            }

            // Remove the second token from the keychain
            do {
                try keychain.deletePersistentToken(savedItem2)
            } catch {
                XCTFail("deletePersistentToken(_:) failed with error: \(error)")
            }

            do {
                let recheckItem1 = try keychain.persistentTokenWithIdentifier(savedItem1.identifier)
                let recheckItem2 = try keychain.persistentTokenWithIdentifier(savedItem2.identifier)
                XCTAssertNil(recheckItem1, "Token should not be in keychain: \(token1)")
                XCTAssertNil(recheckItem2, "Token should not be in keychain: \(token2)")
            } catch {
                XCTFail("persistentTokenWithIdentifier(_:) failed with error: \(error)")
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
        } catch {
            XCTFail("addToken(_:) failed with error: \(error)")
        }
    }

    func testAllPersistentTokens() {
        let token1 = testToken, token2 = testToken, token3 = testToken

        do {
            let noTokens = try keychain.allPersistentTokens()
            XCTAssert(noTokens.isEmpty, "Expected no tokens in keychain: \(noTokens)")
        } catch {
            XCTFail("allPersistentTokens() failed with error: \(error)")
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
            }

            do {
                try keychain.deletePersistentToken(persistentToken1)
                try keychain.deletePersistentToken(persistentToken2)
                try keychain.deletePersistentToken(persistentToken3)
            } catch {
                XCTFail("deletePersistentToken(_:) failed with error: \(error)")
            }

            do {
                let noTokens = try keychain.allPersistentTokens()
                XCTAssert(noTokens.isEmpty, "Expected no tokens in keychain: \(noTokens)")
            } catch {
                XCTFail("allPersistentTokens() failed with error: \(error)")
            }
        } catch {
            XCTFail("addToken(_:) failed with error: \(error)")
        }
    }
}
