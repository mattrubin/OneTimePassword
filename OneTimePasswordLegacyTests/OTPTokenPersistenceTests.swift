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
import OneTimePasswordLegacy


let kValidSecret: [UInt8] = [ 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
    0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f ]

let kValidTokenURL = NSURL(string: "otpauth://totp/L%C3%A9on?algorithm=SHA256&digits=8&period=45&secret=AAAQEAYEAUDAOCAJBIFQYDIOB4")!


class OTPTokenPersistenceTests: XCTestCase {

    func testTokenWithKeychainDictionary() {
        let secret = NSData(bytes: kValidSecret, length: kValidSecret.count)
        guard let urlData = "otpauth://totp/L%C3%A9on?algorithm=SHA256&digits=8&period=45".dataUsingEncoding(NSUTF8StringEncoding),
            let keychainItemRef = NSData(base64EncodedString: "Z2VucAAAAAAAAAAQ", options: [.IgnoreUnknownCharacters]) else {
                XCTFail("Failed to construct keychain data")
                return
        }

        guard let token = OTPToken.tokenWithKeychainDictionary([kSecAttrGeneric as String: urlData,
            kSecValueData as String: secret,
            kSecValuePersistentRef as String: keychainItemRef,
            ]) else {
                XCTFail("Failed to construct token from keychain dictionary")
                return
        }

        XCTAssertEqual(token.type, OTPTokenType.Timer);
        XCTAssertEqual(token.name, "Léon");
        XCTAssertEqual(token.algorithm, OTPAlgorithm.SHA256);
        XCTAssertTrue(abs(token.period - 45.0) < DBL_EPSILON);
        XCTAssertEqual(token.digits, 8);

        XCTAssertEqual(token.secret, secret);

        XCTAssertEqual(token.keychainItemRef, keychainItemRef);
        XCTAssertTrue(token.isInKeychain);

        // Test failure case
        let noToken = OTPToken.tokenWithKeychainDictionary([:])
        XCTAssertNil(noToken, "Token should be nil: \(noToken)");
    }

    func testTokenWithKeychainItemRef() {
        // Create a token
        guard let token = OTPToken.tokenWithURL(kValidTokenURL) else {
            XCTFail("Failed to construct token from url")
            return
        }

        XCTAssertEqual(token.type, OTPTokenType.Timer);
        XCTAssertEqual(token.name, "Léon");
        XCTAssertEqual(token.algorithm, OTPAlgorithm.SHA256);
        XCTAssertTrue(abs(token.period - 45.0) < DBL_EPSILON);
        XCTAssertEqual(token.digits, 8);

        XCTAssertEqual(token.secret, NSData(bytes: kValidSecret, length: kValidSecret.count))

        // Save the token
        XCTAssertFalse(token.isInKeychain);
        XCTAssertNil(token.keychainItemRef);

        XCTAssertTrue(token.saveToKeychain())

        XCTAssertTrue(token.isInKeychain);
        XCTAssertNotNil(token.keychainItemRef);

        // Restore the token
        guard let keychainItemRef = token.keychainItemRef,
            let secondToken = OTPToken.tokenWithKeychainItemRef(keychainItemRef) else {
                XCTFail("Failed to construct token from keychain item ref")
                return
        }


        XCTAssertEqual(secondToken.type, OTPTokenType.Timer);
        XCTAssertEqual(secondToken.name, "Léon");
        XCTAssertEqual(secondToken.algorithm, OTPAlgorithm.SHA256);
        XCTAssertTrue(abs(secondToken.period - 45.0) < DBL_EPSILON);
        XCTAssertEqual(secondToken.digits, 8);

        XCTAssertEqual(secondToken.secret, NSData(bytes: kValidSecret, length: kValidSecret.count))

        XCTAssertEqual(secondToken.keychainItemRef, token.keychainItemRef);
        XCTAssertTrue(secondToken.isInKeychain);

        // Modify the token
        token.type = OTPTokenType.Counter;
        token.name = "???";
        token.digits = 6;

        XCTAssertTrue(token.saveToKeychain());

        // Fetch the token again
        guard let thirdToken = OTPToken.tokenWithKeychainItemRef(keychainItemRef) else {
            XCTFail("Failed to construct token from keychain item ref")
            return
        }

        XCTAssertEqual(thirdToken.type, OTPTokenType.Counter);
        XCTAssertEqual(thirdToken.name, "???");
        XCTAssertEqual(thirdToken.digits, 6);

        XCTAssertEqual(thirdToken.keychainItemRef, token.keychainItemRef);
        XCTAssertTrue(thirdToken.isInKeychain);

        // Remove the token
        XCTAssertTrue(token.isInKeychain);
        XCTAssertNotNil(token.keychainItemRef);

        XCTAssertTrue(token.removeFromKeychain());

        XCTAssertFalse(token.isInKeychain);
        XCTAssertNil(token.keychainItemRef);

        // Attempt to restore the deleted token
        let fourthToken = OTPToken.tokenWithKeychainItemRef(keychainItemRef)
        XCTAssertNil(fourthToken);
    }

    func testDuplicateURLs() {
        guard let token1 = OTPToken.tokenWithURL(kValidTokenURL),
            let token2 = OTPToken.tokenWithURL(kValidTokenURL) else {
                XCTFail("Failed to construct tokens from url.")
                return
        }

        XCTAssertFalse(token1.isInKeychain, "Token should not be in keychain: \(token1)");
        XCTAssertFalse(token2.isInKeychain, "Token should not be in keychain: \(token2)");

        XCTAssertTrue(token1.saveToKeychain(), "Failed to save to keychain: \(token1)");

        XCTAssertTrue(token1.isInKeychain, "Token should be in keychain: \(token1)");
        XCTAssertFalse(token2.isInKeychain, "Token should not be in keychain: \(token2)");

        XCTAssertTrue(token2.saveToKeychain(), "Failed to save to keychain: \(token2)");

        XCTAssertTrue(token1.isInKeychain, "Token should be in keychain: \(token1)");
        XCTAssertTrue(token2.isInKeychain, "Token should be in keychain: \(token2)");

        XCTAssertTrue(token1.removeFromKeychain(), "Failed to remove from keychain: \(token1)");

        XCTAssertFalse(token1.isInKeychain, "Token should not be in keychain: \(token1)");
        XCTAssertTrue(token2.isInKeychain, "Token should be in keychain: \(token2)");

        XCTAssertTrue(token2.removeFromKeychain(), "Failed to remove from keychain: \(token2)");

        XCTAssertFalse(token1.isInKeychain, "Token should not be in keychain: \(token1)");
        XCTAssertFalse(token2.isInKeychain, "Token should not be in keychain: \(token2)");

        XCTAssertFalse(token1.removeFromKeychain(), "Removing again should fail: \(token1)");
        XCTAssertFalse(token2.removeFromKeychain(), "Removing again should fail: \(token2)");
    }

    func _tokenFromArray(tokens: [OTPToken], withKeychainItemRef keychainItemRef: NSData) -> OTPToken? {
        XCTAssertNotNil(tokens, "Can't find a token in a nil array.");
        XCTAssertNotNil(keychainItemRef, "Can't find a token with a nil keychain ref.");

        var foundToken: OTPToken? = nil;
        for token in tokens {
            if foundToken != nil {
                XCTAssertNotEqual(token.keychainItemRef, keychainItemRef, "Found two tokens with identical keychain refs!\n\(foundToken)\n\(token)");
            }
            if let tokenRef = token.keychainItemRef
                where tokenRef.isEqualToData(keychainItemRef) {
                    foundToken = token;
            }
        }
        return foundToken;
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

        XCTAssertNotNil(_tokenFromArray(tokens, withKeychainItemRef: token1.keychainItemRef!), "Token not recovered from keychain: \(token1)");
        XCTAssertNotNil(_tokenFromArray(tokens, withKeychainItemRef: token2.keychainItemRef!), "Token not recovered from keychain: \(token2)");
        XCTAssertNotNil(_tokenFromArray(tokens, withKeychainItemRef: token3.keychainItemRef!), "Token not recovered from keychain: \(token3)");
        
        let keychainRef1 = token1.keychainItemRef;
        let keychainRef2 = token2.keychainItemRef;
        let keychainRef3 = token3.keychainItemRef;
        
        token1.removeFromKeychain()
        token2.removeFromKeychain()
        token3.removeFromKeychain()
        
        let tokensRemaining = OTPToken.allTokensInKeychain()
        
        XCTAssertNil(_tokenFromArray(tokensRemaining, withKeychainItemRef: keychainRef1!), "Token not removed from keychain: \(token1)");
        XCTAssertNil(_tokenFromArray(tokensRemaining, withKeychainItemRef: keychainRef2!), "Token not removed from keychain: \(token2)");
        XCTAssertNil(_tokenFromArray(tokensRemaining, withKeychainItemRef: keychainRef3!), "Token not removed from keychain: \(token3)");
    }
}
