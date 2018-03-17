//
//  KeychainTests.swift
//  OneTimePassword
//
//  Copyright (c) 2013-2017 Matt Rubin and the OneTimePassword authors
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
import Base32

let testToken = Token(
    name: "Name",
    issuer: "Issuer",
    generator: Generator(
        factor: .timer(period: 45),
        secret: MF_Base32Codec.data(fromBase32String: "AAAQEAYEAUDAOCAJBIFQYDIOB4"),
        algorithm: .sha256,
        digits: 8
    )!
)

class KeychainTests: XCTestCase {
    let keychain = Keychain.sharedInstance

    func testPersistentTokenWithIdentifier() {
        // Create a token
        let token = testToken

        // Save the token
        let savedToken: PersistentToken
        do {
            savedToken = try keychain.add(token)
        } catch {
            XCTFail("addToken(_:) failed with error: \(error)")
            return
        }

        // Restore the token
        do {
            let fetchedToken = try keychain.persistentToken(withIdentifier: savedToken.identifier)
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
            let updatedToken = try keychain.update(savedToken, with: modifiedToken)
            XCTAssertEqual(updatedToken.identifier, savedToken.identifier)
            XCTAssertEqual(updatedToken.token, modifiedToken)
        } catch {
            XCTFail("updatePersistentToken(_:withToken:) failed with error: \(error)")
        }

        // Fetch the token again
        do {
            let fetchedToken = try keychain.persistentToken(withIdentifier: savedToken.identifier)
            XCTAssertEqual(fetchedToken?.token, modifiedToken)
            XCTAssertEqual(fetchedToken?.identifier, savedToken.identifier)
        } catch {
            XCTFail("persistentTokenWithIdentifier(_:) failed with error: \(error)")
        }

        // Remove the token
        do {
            try keychain.delete(savedToken)
        } catch {
            XCTFail("deletePersistentToken(_:) failed with error: \(error)")
        }

        // Attempt to restore the deleted token
        do {
            let fetchedToken = try keychain.persistentToken(withIdentifier: savedToken.identifier)
            XCTAssertNil(fetchedToken, "Token should have been removed from keychain")
        } catch {
            XCTFail("persistentTokenWithIdentifier(_:) failed with error: \(error)")
        }
    }

    // swiftlint:disable:next function_body_length
    func testDuplicateTokens() {
        let token1 = testToken, token2 = testToken

        // Add both tokens to the keychain
        let savedItem1: PersistentToken
        let savedItem2: PersistentToken
        do {
            savedItem1 = try keychain.add(token1)
            savedItem2 = try keychain.add(token2)
            XCTAssertEqual(savedItem1.token, token1)
            XCTAssertEqual(savedItem2.token, token2)
        } catch {
            XCTFail("addToken(_:) failed with error: \(error)")
            return
        }

        // Fetch both tokens from the keychain
        do {
            let fetchedItem1 = try keychain.persistentToken(withIdentifier: savedItem1.identifier)
            let fetchedItem2 = try keychain.persistentToken(withIdentifier: savedItem2.identifier)
            XCTAssertEqual(fetchedItem1, savedItem1, "Saved token not found in keychain")
            XCTAssertEqual(fetchedItem2, savedItem2, "Saved token not found in keychain")
        } catch {
            XCTFail("persistentTokenWithIdentifier(_:) failed with error: \(error)")
        }

        // Remove the first token from the keychain
        do {
            try keychain.delete(savedItem1)
        } catch {
            XCTFail("deletePersistentToken(_:) failed with error: \(error)")
        }

        do {
            let checkItem1 = try keychain.persistentToken(withIdentifier: savedItem1.identifier)
            let checkItem2 = try keychain.persistentToken(withIdentifier: savedItem2.identifier)
            XCTAssertNil(checkItem1, "Token should not be in keychain: \(token1)")
            XCTAssertNotNil(checkItem2, "Token should be in keychain: \(token2)")
        } catch {
            XCTFail("persistentTokenWithIdentifier(_:) failed with error: \(error)")
        }

        // Remove the second token from the keychain
        do {
            try keychain.delete(savedItem2)
        } catch {
            XCTFail("deletePersistentToken(_:) failed with error: \(error)")
        }

        do {
            let recheckItem1 = try keychain.persistentToken(withIdentifier: savedItem1.identifier)
            let recheckItem2 = try keychain.persistentToken(withIdentifier: savedItem2.identifier)
            XCTAssertNil(recheckItem1, "Token should not be in keychain: \(token1)")
            XCTAssertNil(recheckItem2, "Token should not be in keychain: \(token2)")
        } catch {
            XCTFail("persistentTokenWithIdentifier(_:) failed with error: \(error)")
        }

        // Try to remove both tokens from the keychain again
        do {
            try keychain.delete(savedItem1)
            // The deletion should throw and this line should never be reached.
            XCTFail("Removing again should fail: \(token1)")
        } catch {
            // An error thrown is the expected outcome
        }
        do {
            try keychain.delete(savedItem2)
            // The deletion should throw and this line should never be reached.
            XCTFail("Removing again should fail: \(token2)")
        } catch {
            // An error thrown is the expected outcome
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

        let persistentToken1: PersistentToken
        let persistentToken2: PersistentToken
        let persistentToken3: PersistentToken
        do {
            persistentToken1 = try keychain.add(token1)
            persistentToken2 = try keychain.add(token2)
            persistentToken3 = try keychain.add(token3)
        } catch {
            XCTFail("addToken(_:) failed with error: \(error)")
            return
        }

        do {
            let allTokens = try keychain.allPersistentTokens()
            XCTAssertEqual(allTokens, [persistentToken1, persistentToken2, persistentToken3],
                           "Tokens not correctly recovered from keychain")
        } catch {
            XCTFail("allPersistentTokens() failed with error: \(error)")
        }

        do {
            try keychain.delete(persistentToken1)
            try keychain.delete(persistentToken2)
            try keychain.delete(persistentToken3)
        } catch {
            XCTFail("deletePersistentToken(_:) failed with error: \(error)")
        }

        do {
            let noTokens = try keychain.allPersistentTokens()
            XCTAssert(noTokens.isEmpty, "Expected no tokens in keychain: \(noTokens)")
        } catch {
            XCTFail("allPersistentTokens() failed with error: \(error)")
        }
    }

    func testMissingData() throws {
        let keychainAttributes: [String: AnyObject] = [
            kSecValueData as String:    testToken.generator.secret as NSData,
        ]

        let persistentRef = try addKeychainItem(withAttributes: keychainAttributes)

        XCTAssertThrowsError(try keychain.persistentToken(withIdentifier: persistentRef))
        XCTAssertThrowsError(try keychain.allPersistentTokens())
    }

    func testMissingSecret() throws {
        let data = try testToken.toURL().absoluteString.data(using: .utf8)!

        let keychainAttributes: [String: AnyObject] = [
            kSecAttrGeneric as String:  data as NSData,
        ]

        let persistentRef = try addKeychainItem(withAttributes: keychainAttributes)

        XCTAssertThrowsError(try keychain.persistentToken(withIdentifier: persistentRef))
        XCTAssertThrowsError(try keychain.allPersistentTokens())
    }

    func testBadData() throws {
        let badData = " ".data(using: .utf8)!

        let keychainAttributes: [String: AnyObject] = [
            kSecAttrGeneric as String:  badData as NSData,
            kSecValueData as String:    testToken.generator.secret as NSData,
        ]

        let persistentRef = try addKeychainItem(withAttributes: keychainAttributes)

        XCTAssertThrowsError(try keychain.persistentToken(withIdentifier: persistentRef))
        XCTAssertThrowsError(try keychain.allPersistentTokens())
    }

    func testBadURL() throws {
        let badData = "http://example.com".data(using: .utf8)!

        let keychainAttributes: [String: AnyObject] = [
            kSecAttrGeneric as String:  badData as NSData,
            kSecValueData as String:    testToken.generator.secret as NSData,
        ]

        let persistentRef = try addKeychainItem(withAttributes: keychainAttributes)

        XCTAssertThrowsError(try keychain.persistentToken(withIdentifier: persistentRef))
        XCTAssertThrowsError(try keychain.allPersistentTokens())
    }

    // MARK: Keychain helpers

    private func addKeychainItem(withAttributes attributes: [String: AnyObject]) throws -> Data {
        var mutableAttributes = attributes
        mutableAttributes[kSecClass as String] = kSecClassGenericPassword
        mutableAttributes[kSecReturnPersistentRef as String] = kCFBooleanTrue
        // Set a random string for the account name.
        // We never query by or display this value, but the keychain requires it to be unique.
        if mutableAttributes[kSecAttrAccount as String] == nil {
            mutableAttributes[kSecAttrAccount as String] = UUID().uuidString as NSString
        }

        var result: AnyObject?
        let resultCode: OSStatus = withUnsafeMutablePointer(to: &result) {
            SecItemAdd(mutableAttributes as CFDictionary, $0)
        }

        guard resultCode == errSecSuccess else {
            throw Keychain.Error.systemError(resultCode)
        }
        guard let persistentRef = result as? Data else {
            throw Keychain.Error.incorrectReturnType
        }
        return persistentRef
    }
}
