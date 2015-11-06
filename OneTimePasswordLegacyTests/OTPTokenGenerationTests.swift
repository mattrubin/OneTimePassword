//
//  OTPTokenGenerationTests.swift
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
@testable import OneTimePassword
@testable import OneTimePasswordLegacy

class OTPTokenGenerationTests: XCTestCase {
    // The values in this test are found in Appendix D of the HOTP RFC
    // https://tools.ietf.org/html/rfc4226#appendix-D
    func testHOTPRFCValues() {
        let secret = "12345678901234567890".dataUsingEncoding(NSASCIIStringEncoding)!
        let token = OTPToken()
        token.type = .Counter
        token.secret = secret
        token.algorithm = .SHA1
        token.digits = 6
        token.counter = 0

        XCTAssertEqual("755224", token.password, "The 0th OTP should be the expected string.")
        XCTAssertEqual("755224", token.password, "The password property should be idempotent.")

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

        for expectedPassword in expectedValues {
            token.updatePassword()
            XCTAssertEqual(token.password, expectedPassword, "The generator did not produce the expected OTP.")
        }
    }

    // The values in this test are found in Appendix B of the TOTP RFC
    // https://tools.ietf.org/html/rfc6238#appendix-B
    func testTOTPRFCValues() {
        let secretKeys: [Generator.Algorithm: String] = [
            .SHA1:   "12345678901234567890",
            .SHA256: "12345678901234567890123456789012",
            .SHA512: "1234567890123456789012345678901234567890123456789012345678901234",
        ]

        let times: [NSTimeInterval] = [
            59,
            1111111109,
            1111111111,
            1234567890,
            2000000000,
            20000000000,
        ]

        let expectedValues: [Generator.Algorithm: [String]] = [
            .SHA1:   ["94287082", "07081804", "14050471", "89005924", "69279037", "65353130"],
            .SHA256: ["46119246", "68084774", "67062674", "91819424", "90698825", "77737706"],
            .SHA512: ["90693936", "25091201", "99943326", "93441116", "38618901", "47863826"],
        ]

        for (algorithm, secretKey) in secretKeys {
            let secret = secretKey.dataUsingEncoding(NSASCIIStringEncoding)!
            let generator = Generator(factor: .Timer(period: 30), secret: secret, algorithm: algorithm, digits: 8)

            for i in 0..<times.count {
                let expectedPassword = expectedValues[algorithm]?[i]
                XCTAssertEqual(try! generator.passwordAtTimeIntervalSince1970(times[i]), expectedPassword,
                    "The generator did not produce the expected OTP.")
            }
        }
    }

    // From Google Authenticator for iOS
    // https://code.google.com/p/google-authenticator/source/browse/mobile/ios/Classes/TOTPGeneratorTest.m
    func testTOTPGoogleValues() {
        let secret = "12345678901234567890".dataUsingEncoding(NSASCIIStringEncoding)!

        let intervals: [NSTimeInterval] = [
            1111111111,
            1234567890,
            2000000000,
        ]
        let algorithms: [Generator.Algorithm] = [
            .SHA1,
            .SHA256,
            .SHA512,
        ]
        let results = [
            // SHA1    SHA256    SHA512
            "050471", "584430", "380122", // date1
            "005924", "829826", "671578", // date2
            "279037", "428693", "464532", // date3
        ]

        var j = 0
        for i in 0..<intervals.count {
            for algorithm in algorithms {
                let generator = Generator(factor: .Timer(period: 30), secret: secret, algorithm: algorithm, digits: 6)
                XCTAssertEqual(results[j],
                               try! generator.passwordAtTimeIntervalSince1970(intervals[i]),
                               "Invalid result \(i), \(algorithm), \(intervals[i])")
                j++
            }
        }
    }
}
