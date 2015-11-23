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
import Security.SecItem
import OneTimePassword
import OneTimePasswordLegacy

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
        guard let token1 = OTPToken.tokenWithURL(kValidTokenURL),
            let token2 = OTPToken.tokenWithURL(kValidTokenURL) else {
                XCTFail("Failed to construct tokens from url.")
                return
        }

        XCTAssertFalse(token1.isInKeychain, "Token should not be in keychain: \(token1)")
        XCTAssertFalse(token2.isInKeychain, "Token should not be in keychain: \(token2)")

        XCTAssertTrue(token1.saveToKeychain(), "Failed to save to keychain: \(token1)")

        XCTAssertTrue(token1.isInKeychain, "Token should be in keychain: \(token1)")
        XCTAssertFalse(token2.isInKeychain, "Token should not be in keychain: \(token2)")

        XCTAssertTrue(token2.saveToKeychain(), "Failed to save to keychain: \(token2)")

        XCTAssertTrue(token1.isInKeychain, "Token should be in keychain: \(token1)")
        XCTAssertTrue(token2.isInKeychain, "Token should be in keychain: \(token2)")

        XCTAssertTrue(token1.removeFromKeychain(), "Failed to remove from keychain: \(token1)")

        XCTAssertFalse(token1.isInKeychain, "Token should not be in keychain: \(token1)")
        XCTAssertTrue(token2.isInKeychain, "Token should be in keychain: \(token2)")

        XCTAssertTrue(token2.removeFromKeychain(), "Failed to remove from keychain: \(token2)")

        XCTAssertFalse(token1.isInKeychain, "Token should not be in keychain: \(token1)")
        XCTAssertFalse(token2.isInKeychain, "Token should not be in keychain: \(token2)")

        XCTAssertFalse(token1.removeFromKeychain(), "Removing again should fail: \(token1)")
        XCTAssertFalse(token2.removeFromKeychain(), "Removing again should fail: \(token2)")
    }

    func _tokenFromArray(tokens: [OTPToken], withKeychainItemRef keychainItemRef: NSData) -> OTPToken? {
        let matchingTokens = tokens.filter({ $0.keychainItemRef == keychainItemRef })
        XCTAssert((matchingTokens.count <= 1),
            "Found more than one matching token: \(matchingTokens)")
        return matchingTokens.first
    }

    func testAllTokensInKeychain() {
        guard let token1 = OTPToken.tokenWithURL(kValidTokenURL),
            let token2 = OTPToken.tokenWithURL(kValidTokenURL),
            let token3 = OTPToken.tokenWithURL(kValidTokenURL) else {
                XCTFail("Failed to construct tokens from URL")
                return
        }

        token1.saveToKeychain()
        token2.saveToKeychain()
        token3.saveToKeychain()

        let tokens = OTPToken.allTokensInKeychain()

        XCTAssertNotNil(_tokenFromArray(tokens, withKeychainItemRef: token1.keychainItemRef!),
            "Token not recovered from keychain: \(token1)")
        XCTAssertNotNil(_tokenFromArray(tokens, withKeychainItemRef: token2.keychainItemRef!),
            "Token not recovered from keychain: \(token2)")
        XCTAssertNotNil(_tokenFromArray(tokens, withKeychainItemRef: token3.keychainItemRef!),
            "Token not recovered from keychain: \(token3)")

        let keychainRef1 = token1.keychainItemRef
        let keychainRef2 = token2.keychainItemRef
        let keychainRef3 = token3.keychainItemRef

        token1.removeFromKeychain()
        token2.removeFromKeychain()
        token3.removeFromKeychain()

        let tokensRemaining = OTPToken.allTokensInKeychain()

        XCTAssertNil(_tokenFromArray(tokensRemaining, withKeychainItemRef: keychainRef1!),
            "Token not removed from keychain: \(token1)")
        XCTAssertNil(_tokenFromArray(tokensRemaining, withKeychainItemRef: keychainRef2!),
            "Token not removed from keychain: \(token2)")
        XCTAssertNil(_tokenFromArray(tokensRemaining, withKeychainItemRef: keychainRef3!),
            "Token not removed from keychain: \(token3)")
    }
}
