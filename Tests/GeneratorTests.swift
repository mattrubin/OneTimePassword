//
//  GeneratorTests.swift
//  OneTimePassword
//
//  Copyright (c) 2014-2019 Matt Rubin and the OneTimePassword authors
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

class GeneratorTests: XCTestCase {
    func testInit() {
        // Create a generator
        let factor = OneTimePassword.Generator.Factor.counter(111)
        let secret = "12345678901234567890".data(using: String.Encoding.ascii)!
        let algorithm = Generator.Algorithm.sha256
        let digits = 8

        let generator = Generator(
            factor: factor,
            secret: secret,
            algorithm: algorithm,
            digits: digits,
            representation: .numeric
        )

        XCTAssertEqual(generator?.factor, factor)
        XCTAssertEqual(generator?.secret, secret)
        XCTAssertEqual(generator?.algorithm, algorithm)
        XCTAssertEqual(generator?.digits, digits)

        // Create another generator
        let otherFactor = OneTimePassword.Generator.Factor.timer(period: 123)
        let otherSecret = "09876543210987654321".data(using: String.Encoding.ascii)!
        let otherAlgorithm = Generator.Algorithm.sha512
        let otherDigits = 7

        let otherGenerator = Generator(
            factor: otherFactor,
            secret: otherSecret,
            algorithm: otherAlgorithm,
            digits: otherDigits,
            representation: .numeric
        )

        XCTAssertEqual(otherGenerator?.factor, otherFactor)
        XCTAssertEqual(otherGenerator?.secret, otherSecret)
        XCTAssertEqual(otherGenerator?.algorithm, otherAlgorithm)
        XCTAssertEqual(otherGenerator?.digits, otherDigits)

        // Ensure the generators are different
        XCTAssertNotEqual(generator?.factor, otherGenerator?.factor)
        XCTAssertNotEqual(generator?.secret, otherGenerator?.secret)
        XCTAssertNotEqual(generator?.algorithm, otherGenerator?.algorithm)
        XCTAssertNotEqual(generator?.digits, otherGenerator?.digits)
    }

    func testCounter() {
        let factors: [(TimeInterval, TimeInterval, UInt64)] = [
            // swiftlint:disable comma
            (100,         30, 3),
            (10000,       30, 333),
            (1000000,     30, 33333),
            (100000000,   60, 1666666),
            (10000000000, 90, 111111111),
            // swiftlint:enable comma
        ]

        for (timeSinceEpoch, period, count) in factors {
            let time = Date(timeIntervalSince1970: timeSinceEpoch)
            let timer = Generator.Factor.timer(period: period)
            let counter = Generator.Factor.counter(count)
            let secret = "12345678901234567890".data(using: String.Encoding.ascii)!
            let hotp = Generator(factor: counter, secret: secret, algorithm: .sha1, digits: 6, representation: .numeric)
                .flatMap { try? $0.password(at: time) }
            let totp = Generator(factor: timer, secret: secret, algorithm: .sha1, digits: 6, representation: .numeric)
                .flatMap { try? $0.password(at: time) }
            XCTAssertEqual(hotp, totp,
                           "TOTP with \(timer) should match HOTP with counter \(counter) at time \(time).")
        }
    }

    func testValidation() {
        let digitTests: [(Int, Bool)] = [
            (-6, false),
            (0, false),
            (1, false),
            (5, false),
            (6, true),
            (7, true),
            (8, true),
            (9, false),
            (10, false),
        ]

        let periodTests: [(TimeInterval, Bool)] = [
            (-30, false),
            (0, false),
            (1, true),
            (30, true),
            (300, true),
            (301, true),
        ]

        for (digits, digitsAreValid) in digitTests {
            let generator = Generator(
                factor: .counter(0),
                secret: Data(),
                algorithm: .sha1,
                digits: digits,
                representation: .numeric
            )
            // If the digits are invalid, password generation should throw an error
            let generatorIsValid = digitsAreValid
            if generatorIsValid {
                XCTAssertNotNil(generator)
            } else {
                XCTAssertNil(generator)
            }

            for (period, periodIsValid) in periodTests {
                let generator = Generator(
                    factor: .timer(period: period),
                    secret: Data(),
                    algorithm: .sha1,
                    digits: digits,
                    representation: .numeric
                )
                // If the digits or period are invalid, password generation should throw an error
                let generatorIsValid = digitsAreValid && periodIsValid
                if generatorIsValid {
                    XCTAssertNotNil(generator)
                } else {
                    XCTAssertNil(generator)
                }
            }
        }
    }

    func testPasswordAtInvalidTime() {
        guard let generator = Generator(
            factor: .timer(period: 30),
            secret: Data(),
            algorithm: .sha1,
            digits: 6,
            representation: .numeric
            ) else {
                XCTFail("Failed to initialize a Generator.")
                return
        }

        let badTime = Date(timeIntervalSince1970: -100)
        do {
            _ = try generator.password(at: badTime)
        } catch Generator.Error.invalidTime {
            // This is the expected type of error
            return
        } catch {
            XCTFail("passwordAtTime(\(badTime)) threw an unexpected type of error: \(error))")
            return
        }
        XCTFail("passwordAtTime(\(badTime)) should throw an error)")
    }

    func testPasswordWithInvalidPeriod() {
        // It should not be possible to try to get a password from a generator with an invalid period, because the
        // generator initializer should fail when given an invalid period.
        let generator = Generator(factor: .timer(period: 0), secret: Data(), algorithm: .sha1, digits: 8, representation: .numeric)
        XCTAssertNil(generator)
    }

    func testPasswordWithInvalidDigits() {
        // It should not be possible to try to get a password from a generator with an invalid digit count, because the
        // generator initializer should fail when given an invalid digit count.
        let generator = Generator(factor: .timer(period: 30), secret: Data(), algorithm: .sha1, digits: 3, representation: .numeric)
        XCTAssertNil(generator)
    }

    // The values in this test are found in Appendix D of the HOTP RFC
    // https://tools.ietf.org/html/rfc4226#appendix-D
    func testHOTPRFCValues() {
        let secret = "12345678901234567890".data(using: String.Encoding.ascii)!
        let expectedValues: [UInt64: String] = [
            0: "755224",
            1: "287082",
            2: "359152",
            3: "969429",
            4: "338314",
            5: "254676",
            6: "287922",
            7: "162583",
            8: "399871",
            9: "520489",
        ]
        for (counter, expectedPassword) in expectedValues {
            let generator = Generator(factor: .counter(counter), secret: secret, algorithm: .sha1, digits: 6, representation: .numeric)
            let time = Date(timeIntervalSince1970: 0)
            let password = generator.flatMap { try? $0.password(at: time) }
            XCTAssertEqual(password, expectedPassword,
                           "The generator did not produce the expected OTP.")
        }
    }

    // The values in this test are found in Appendix B of the TOTP RFC
    // https://tools.ietf.org/html/rfc6238#appendix-B
    func testTOTPRFCValues() {
        let secretKeys: [Generator.Algorithm: String] = [
            .sha1:   "12345678901234567890",
            .sha256: "12345678901234567890123456789012",
            .sha512: "1234567890123456789012345678901234567890123456789012345678901234",
        ]

        let timesSinceEpoch: [TimeInterval] = [59, 1111111109, 1111111111, 1234567890, 2000000000, 20000000000]

        let expectedValues: [Generator.Algorithm: [String]] = [
            .sha1:   ["94287082", "07081804", "14050471", "89005924", "69279037", "65353130"],
            .sha256: ["46119246", "68084774", "67062674", "91819424", "90698825", "77737706"],
            .sha512: ["90693936", "25091201", "99943326", "93441116", "38618901", "47863826"],
        ]

        for (algorithm, secretKey) in secretKeys {
            let secret = secretKey.data(using: String.Encoding.ascii)!
            let generator = Generator(factor: .timer(period: 30), secret: secret, algorithm: algorithm, digits: 8, representation: .numeric)

            for (timeSinceEpoch, expectedPassword) in zip(timesSinceEpoch, expectedValues[algorithm]!) {
                let time = Date(timeIntervalSince1970: timeSinceEpoch)
                let password = generator.flatMap { try? $0.password(at: time) }
                XCTAssertEqual(password, expectedPassword,
                               "Incorrect result for \(algorithm) at \(timeSinceEpoch)")
            }
        }
    }

    // From Google Authenticator for iOS
    // https://code.google.com/p/google-authenticator/source/browse/mobile/ios/Classes/TOTPGeneratorTest.m
    func testTOTPGoogleValues() {
        let secret = "12345678901234567890".data(using: String.Encoding.ascii)!
        let timesSinceEpoch: [TimeInterval] = [1111111111, 1234567890, 2000000000]

        let expectedValues: [Generator.Algorithm: [String]] = [
            .sha1:   ["050471", "005924", "279037"],
            .sha256: ["584430", "829826", "428693"],
            .sha512: ["380122", "671578", "464532"],
        ]

        for (algorithm, expectedPasswords) in expectedValues {
            let generator = Generator(factor: .timer(period: 30), secret: secret, algorithm: algorithm, digits: 6, representation: .numeric)
            for (timeSinceEpoch, expectedPassword) in zip(timesSinceEpoch, expectedPasswords) {
                let time = Date(timeIntervalSince1970: timeSinceEpoch)
                let password = generator.flatMap { try? $0.password(at: time) }
                XCTAssertEqual(password, expectedPassword,
                               "Incorrect result for \(algorithm) at \(timeSinceEpoch)")
            }
        }
    }

    // The values in this test were extracted manually using a test Steam account.
    func testSteamGuardTOTPValues() {
        let secret = MF_Base32Codec.data(fromBase32String: "I6FMHELVR57Z2PCNB7D22MS6I2SRSQIB")!
        let expectedValues: [TimeInterval: String] = [
            1590895077: "Y4323",
            1590895162: "RFQNR",
        ]

        let generator = Generator(factor: .timer(period: 30), secret: secret, algorithm: .sha1, digits: 5, representation: .steamguard)
        for (timeSinceEpoch, expectedPassword) in expectedValues {
            let time = Date(timeIntervalSince1970: timeSinceEpoch)
            let password = generator.flatMap { try? $0.password(at: time) }
            XCTAssertEqual(password, expectedPassword,
                           "Incorrect result for Steam Guard at \(timeSinceEpoch)")
        }
    }
}
