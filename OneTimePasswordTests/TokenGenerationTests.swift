//
//  TokenGenerationTests.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/9/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import XCTest
import OneTimePassword

class TokenGenerationTests: XCTestCase {
    // The values in this test are found in Appendix D of the HOTP RFC
    // https://tools.ietf.org/html/rfc4226#appendix-D
    func testHOTPRFCValues() {
        let secret = "12345678901234567890".dataUsingEncoding(NSASCIIStringEncoding)!
        let expectedValues = ["755224", "287082", "359152", "969429", "338314", "254676", "287922", "162583", "399871", "520489"]

        var token = Token(type: .Counter(0), secret: secret, algorithm: .SHA1, digits: 6, counter: 0)

        for (var counter = 0; counter < expectedValues.count; counter++) {
            XCTAssertEqual(token.passwordForCounter(UInt64(counter))!, expectedValues[counter])
            XCTAssertEqual(token.passwordForCounter(UInt64(counter))!, expectedValues[counter],
                "Inconsistent return value from token.passwordForCounter(\(counter))")
        }

        for expectedPassword: String in expectedValues {
            XCTAssertEqual(token.password()!, expectedPassword)
            XCTAssertEqual(token.password()!, expectedPassword,
                "Inconsistent return value from token.password()")
            token = token.updatedToken()
        }
    }

    // The values in this test are found in Appendix B of the TOTP RFC
    // https://tools.ietf.org/html/rfc6238#appendix-B
    func testTOTPRFCValues() {
        let secretKeys = [
            Token.Algorithm.SHA1:   "12345678901234567890",
            Token.Algorithm.SHA256: "12345678901234567890123456789012",
            Token.Algorithm.SHA512: "1234567890123456789012345678901234567890123456789012345678901234",
        ]

        let times: Array<NSTimeInterval> = [59, 1111111109, 1111111111, 1234567890, 2000000000, 20000000000]

        let expectedValues = [
            Token.Algorithm.SHA1:   ["94287082", "07081804", "14050471", "89005924", "69279037", "65353130"],
            Token.Algorithm.SHA256: ["46119246", "68084774", "67062674", "91819424", "90698825", "77737706"],
            Token.Algorithm.SHA512: ["90693936", "25091201", "99943326", "93441116", "38618901", "47863826"],
        ]

        for (algorithm, secretKey) in secretKeys {
            let secret = secretKey.dataUsingEncoding(NSASCIIStringEncoding)!
            let token = Token(type: .Timer(30), secret: secret, algorithm: algorithm, digits: 8, period: 30)

            for (var i = 0; i < times.count; i++) {
                if let password = expectedValues[algorithm]?[i] {
                    let counter = UInt64(times[i] / token.period)
                    XCTAssertEqual(token.passwordForCounter(counter)!, password, "Incorrect result for \(algorithm) at \(times[i])")
                    XCTAssertEqual(token.passwordForCounter(counter)!, password, "Inconsistent result for \(algorithm) at \(times[i])")
                }
            }
        }
    }

    // From Google Authenticator for iOS
    // https://code.google.com/p/google-authenticator/source/browse/mobile/ios/Classes/TOTPGeneratorTest.m
    func testTOTPGoogleValues() {
        let secret = "12345678901234567890".dataUsingEncoding(NSASCIIStringEncoding)!
        let times = [1111111111, 1234567890, 2000000000]

        let expectedValues = [
            Token.Algorithm.SHA1:   ["050471", "005924", "279037"],
            Token.Algorithm.SHA256: ["584430", "829826", "428693"],
            Token.Algorithm.SHA512: ["380122", "671578", "464532"],
        ]

        for (algorithm, values) in expectedValues {
            let token = Token(type: .Timer(30), secret: secret, algorithm: algorithm, digits: 6, period: 30)
            for (var i = 0; i < times.count; i++) {
                let counter = UInt64(NSTimeInterval(times[i]) / token.period)
                XCTAssertEqual(values[i], token.passwordForCounter(counter)!,
                    "Incorrect result for \(algorithm) at \(times[i])")
            }
        }
    }
}
