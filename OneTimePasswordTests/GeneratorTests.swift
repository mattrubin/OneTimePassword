//
//  GeneratorTests.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/9/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import XCTest
import OneTimePassword

class GeneratorTests: XCTestCase {
    func testCounter() {
        let factors: [(OneTimePassword.Generator.Factor, NSTimeInterval, UInt64)] = [
            (.Counter(0),           -1,             0),
            (.Counter(1),           -1,             1),
            (.Counter(123),         -1,             123),
            (.Counter(99999),       -1,             99999),
            (.Timer(period: 30),    100,            3),
            (.Timer(period: 30),    10000,          333),
            (.Timer(period: 30),    1000000,        33333),
            (.Timer(period: 60),    100000000,      1666666),
            (.Timer(period: 90),    10000000000,    111111111),
        ]

        for (factor, timeInterval, counter) in factors {
            XCTAssertEqual(counterForTokenWithFactor(factor, atTimeIntervalSince1970: timeInterval), counter)
        }
    }

    // The values in this test are found in Appendix D of the HOTP RFC
    // https://tools.ietf.org/html/rfc4226#appendix-D
    func testHOTPRFCValues() {
        let secret = "12345678901234567890".dataUsingEncoding(NSASCIIStringEncoding)!
        let expectedValues = ["755224", "287082", "359152", "969429", "338314", "254676", "287922", "162583", "399871", "520489"]

        for (var counter = 0; counter < expectedValues.count; counter++) {
            XCTAssertEqual(generatePassword(.SHA1, 6, secret, UInt64(counter)), expectedValues[counter])
        }
    }

    // The values in this test are found in Appendix B of the TOTP RFC
    // https://tools.ietf.org/html/rfc6238#appendix-B
    func testTOTPRFCValues() {
        let secretKeys = [
            Generator.Algorithm.SHA1:   "12345678901234567890",
            Generator.Algorithm.SHA256: "12345678901234567890123456789012",
            Generator.Algorithm.SHA512: "1234567890123456789012345678901234567890123456789012345678901234",
        ]

        let times: [NSTimeInterval] = [59, 1111111109, 1111111111, 1234567890, 2000000000, 20000000000]

        let expectedValues = [
            Generator.Algorithm.SHA1:   ["94287082", "07081804", "14050471", "89005924", "69279037", "65353130"],
            Generator.Algorithm.SHA256: ["46119246", "68084774", "67062674", "91819424", "90698825", "77737706"],
            Generator.Algorithm.SHA512: ["90693936", "25091201", "99943326", "93441116", "38618901", "47863826"],
        ]

        for (algorithm, secretKey) in secretKeys {
            let secret = secretKey.dataUsingEncoding(NSASCIIStringEncoding)!

            for (var i = 0; i < times.count; i++) {
                if let password = expectedValues[algorithm]?[i] {
                    let counter = UInt64(times[i] / 30)
                    XCTAssertEqual(generatePassword(algorithm, 8, secret, counter), password, "Incorrect result for \(algorithm) at \(times[i])")
                }
            }
        }
    }

    // From Google Authenticator for iOS
    // https://code.google.com/p/google-authenticator/source/browse/mobile/ios/Classes/TOTPGeneratorTest.m
    func testTOTPGoogleValues() {
        let secret = "12345678901234567890".dataUsingEncoding(NSASCIIStringEncoding)!
        let times: [NSTimeInterval] = [1111111111, 1234567890, 2000000000]

        let expectedValues = [
            Generator.Algorithm.SHA1:   ["050471", "005924", "279037"],
            Generator.Algorithm.SHA256: ["584430", "829826", "428693"],
            Generator.Algorithm.SHA512: ["380122", "671578", "464532"],
        ]

        for (algorithm, values) in expectedValues {
            for (var i = 0; i < times.count; i++) {
                let counter = UInt64(times[i] / 30)
                XCTAssertEqual(values[i], generatePassword(algorithm, 6, secret, counter),
                    "Incorrect result for \(algorithm) at \(times[i])")
            }
        }
    }
}
