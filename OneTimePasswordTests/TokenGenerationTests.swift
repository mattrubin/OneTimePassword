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
        let secret = "12345678901234567890".dataUsingEncoding(NSASCIIStringEncoding)
        let token = OTPToken()
        token.type = .Counter
        token.secret = secret
        token.algorithm = .SHA1
        token.digits = 6
        token.counter = 0

        XCTAssertEqualObjects("755224", token.generatePasswordForCounter(0), "The 0th OTP should be the expected string.")
        XCTAssertEqualObjects("755224", token.generatePasswordForCounter(0), "The generatePasswordForCounter: method should be idempotent.")

        let expectedValues = [
            "287082",
            "359152",
            "969429",
            "338314",
            "254676",
            "287922",
            "162583",
            "399871",
            "520489",
        ]

        for expectedPassword: String in expectedValues {
            token.updatePassword()
            XCTAssertEqualObjects(token.password(), expectedPassword, "The generator did not produce the expected OTP.")
        }
    }

    // The values in this test are found in Appendix B of the TOTP RFC
    // https://tools.ietf.org/html/rfc6238#appendix-B
    func testTOTPRFCValues() {
        let secretKeys = [
            OTPAlgorithm.SHA1:   "12345678901234567890",
            OTPAlgorithm.SHA256: "12345678901234567890123456789012",
            OTPAlgorithm.SHA512: "1234567890123456789012345678901234567890123456789012345678901234",
        ]

        let times: Array<NSTimeInterval> = [
            59,
            1111111109,
            1111111111,
            1234567890,
            2000000000,
            20000000000,
        ]

        let expectedValues = [
            OTPAlgorithm.SHA1:   ["94287082", "07081804", "14050471", "89005924", "69279037", "65353130"],
            OTPAlgorithm.SHA256: ["46119246", "68084774", "67062674", "91819424", "90698825", "77737706"],
            OTPAlgorithm.SHA512: ["90693936", "25091201", "99943326", "93441116", "38618901", "47863826"],
        ]

        for (algorithm, secretKey) in secretKeys {
            let secret = secretKey.dataUsingEncoding(NSASCIIStringEncoding)
            let token = OTPToken()
            token.type = .Timer
            token.secret = secret
            token.algorithm = algorithm
            token.digits = 8
            token.period = 30

            for (var i = 0; i < times.count; i++) {
                if let password = expectedValues[algorithm]?[i] {
                    token.counter = UInt64(times[i] / token.period)
                    XCTAssertEqualObjects(token.generatePasswordForCounter(token.counter), password, "The generator did not produce the expected OTP.")
                }
            }
        }
    }

    // From Google Authenticator for iOS
    // https://code.google.com/p/google-authenticator/source/browse/mobile/ios/Classes/TOTPGeneratorTest.m
    func testTOTPGoogleValues() {
        let secret = "12345678901234567890".dataUsingEncoding(NSASCIIStringEncoding)
        let intervals: Array<NSTimeInterval> = [1111111111, 1234567890, 2000000000]
        let algorithms = [OTPAlgorithm.SHA1, OTPAlgorithm.SHA256, OTPAlgorithm.SHA512]

        let results = [
            // SHA1    SHA256    SHA512
            "050471", "584430", "380122", // date1
            "005924", "829826", "671578", // date2
            "279037", "428693", "464532", // date3
        ]

        for (var i = 0, j = 0; i < intervals.count; i++) {
            for algorithm in algorithms {
                let token = OTPToken()
                token.type = .Timer
                token.secret = secret
                token.algorithm = algorithm
                token.digits = 6
                token.period = 30
                token.counter = UInt64(intervals[i] / token.period)
                
                XCTAssertEqualObjects(results[j],
                                      token.generatePasswordForCounter(token.counter),
                                      "Invalid result \(i), \(algorithm), \(intervals[i])")
                j++
            }
        }
    }
}
