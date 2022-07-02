//
//  TokenSerializationTests.swift
//  OneTimePassword
//
//  Copyright (c) 2014-2018 Matt Rubin and the OneTimePassword authors
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

class TokenSerializationTests: XCTestCase {
    let kOTPScheme = "otpauth"
    let kOTPTokenTypeCounterHost = "hotp"
    let kOTPTokenTypeTimerHost   = "totp"

    let factors: [OneTimePassword.Generator.Factor] = [
        .counter(0),
        .counter(1),
        .counter(UInt64.max),
        .timer(period: 1),
        .timer(period: 30),
        .timer(period: 300),
    ]
    let names = ["", "Login", "user_123@website.com", "Léon", ":/?#[]@!$&'()*+,;=%\""]
    let issuers = ["", "Big Cörpøráçìôn", ":/?#[]@!$&'()*+,;=%\""]
    let secretStrings = [
        "12345678901234567890",
        "12345678901234567890123456789012",
        "1234567890123456789012345678901234567890123456789012345678901234",
        "",
    ]
    let algorithms: [OneTimePassword.Generator.Algorithm] = [.sha1, .sha256, .sha512]
    let digits = [6, 7, 8]

    // swiftlint:disable:next function_body_length
    func testSerialization() {
        for factor in factors {
            for name in names {
                for issuer in issuers {
                    for secretString in secretStrings {
                        for algorithm in algorithms {
                            for digitNumber in digits {
                                // Create the token
                                guard let generator = Generator(
                                    factor: factor,
                                    secret: secretString.data(using: String.Encoding.ascii)!,
                                    algorithm: algorithm,
                                    digits: digitNumber
                                ) else {
                                    XCTFail("Failed to construct Generator.")
                                    continue
                                }

                                let token = Token(
                                    name: name,
                                    issuer: issuer,
                                    generator: generator
                                )

                                // Serialize
                                guard let url = try? token.toURL() else {
                                    XCTFail("Failed to convert Token to URL")
                                    continue
                                }

                                // Test scheme
                                XCTAssertEqual(url.scheme, kOTPScheme, "The url scheme should be \"\(kOTPScheme)\"")
                                // Test Factor
                                var expectedHost: String
                                switch factor {
                                case .counter:
                                    expectedHost = kOTPTokenTypeCounterHost
                                case .timer:
                                    expectedHost = kOTPTokenTypeTimerHost
                                }
                                XCTAssertEqual(url.host!, expectedHost, "The url host should be \"\(expectedHost)\"")
                                // Test name
                                XCTAssertEqual(url.path, "/" + name, "The url path should be \"/\(name)\"")

                                let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
                                let items = urlComponents?.queryItems
                                let expectedItemCount = 5
                                XCTAssertEqual(items?.count, expectedItemCount,
                                               "There shouldn't be any unexpected query arguments: \(url)")
                                // swiftlint:enable vertical_parameter_alignment_on_call

                                var queryArguments: [String: String] = [:]
                                for item in items ?? [] {
                                    queryArguments[item.name] = item.value
                                }
                                XCTAssertEqual(queryArguments.count, expectedItemCount,
                                               "There shouldn't be any unexpected query arguments: \(url)")

                                // Test algorithm
                                let algorithmString: String = {
                                    switch $0 {
                                    case .sha1:
                                        return "SHA1"
                                    case .sha256:
                                        return "SHA256"
                                    case .sha512:
                                        return "SHA512"
                                    }}(algorithm)
                                XCTAssertEqual(queryArguments["algorithm"]!, algorithmString,
                                               "The algorithm value should be \"\(algorithmString)\"")
                                // Test digits
                                XCTAssertEqual(queryArguments["digits"]!, String(digitNumber),
                                               "The digits value should be \"\(digitNumber)\"")
                                // Test representation
                                let representationString: String = {
                                    switch $0 {
                                    case .numeric:
                                        return "numeric"
                                    case .steamguard:
                                        return "steamguard"
                                    }
                                }(generator.representation)
                                XCTAssertEqual(queryArguments["representation"]!, representationString,
                                             "The url query string should not contain the secret")
                                // Test secret
                                XCTAssertNil(queryArguments["secret"],
                                             "The url query string should not contain the secret")

                                // Test period
                                switch factor {
                                case .timer(let period):
                                    XCTAssertEqual(queryArguments["period"]!, String(Int(period)),
                                                   "The period value should be \"\(period)\"")
                                default:
                                    XCTAssertNil(queryArguments["period"],
                                                 "The url query string should not contain the period")
                                }
                                // Test counter
                                switch factor {
                                case .counter(let counter):
                                    XCTAssertEqual(queryArguments["counter"]!, String(counter),
                                                   "The counter value should be \"\(counter)\"")
                                default:
                                    XCTAssertNil(queryArguments["counter"],
                                                 "The url query string should not contain the counter")
                                }

                                // Test issuer
                                XCTAssertEqual(queryArguments["issuer"]!, issuer,
                                               "The issuer value should be \"\(issuer)\"")

                                // Check url again
                                guard let checkURL = try? token.toURL() else {
                                    XCTFail("Failed to convert Token to URL")
                                    continue
                                }
                                XCTAssertEqual(url, checkURL, "Repeated calls to url() should return the same result!")
                            }
                        }
                    }
                }
            }
        }
    }

    func testSteamGuardSerialization() {
        // There is only one valid configuration of factor, algorithm, digits, and representation for Steam Guard.
        // Create the token
        let secretString = "12345678901234567890"
        guard let generator = Generator(
            factor: .timer(period: 30),
            secret: secretString.data(using: String.Encoding.ascii)!,
            algorithm: .sha1,
            digits: 5,
            representation: .steamguard
        ) else {
            XCTFail("Failed to construct Generator.")
            return
        }

        let name = "testaccount"
        let issuer = "Steam"
        let token = Token(
            name: name,
            issuer: issuer,
            generator: generator
        )

        // Serialize
        guard let url = try? token.toURL() else {
            XCTFail("Failed to convert Token to URL")
            return
        }

        // Test scheme
        XCTAssertEqual(url.scheme, kOTPScheme, "The url scheme should be \"\(kOTPScheme)\"")
        // Test Factor
        let expectedHost: String = kOTPTokenTypeTimerHost
        XCTAssertEqual(url.host!, expectedHost, "The url host should be \"\(expectedHost)\"")
        // Test name
        XCTAssertEqual(url.path, "/" + name, "The url path should be \"/\(name)\"")

        let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryArguments: [String: String] = urlComponents?.queryItems?.reduce(into: [:]) { acc, cur in
            acc[cur.name] = cur.value
        } ?? [:]
        let expectedItemCount = 5
        XCTAssertEqual(queryArguments.count, expectedItemCount,
                       "There shouldn't be any unexpected query arguments: \(url)")
        // swiftlint:enable vertical_parameter_alignment_on_call

        // Test algorithm
        let algorithmString = "SHA1"
        XCTAssertEqual(queryArguments["algorithm"]!, algorithmString,
                       "The algorithm value should be \"\(algorithmString)\"")
        // Test digits
        let digitNumber = 5
        XCTAssertEqual(queryArguments["digits"]!, String(digitNumber),
                       "The digits value should be \"\(digitNumber)\"")
        // Test representation
        let representationString = "steamguard"
        XCTAssertEqual(queryArguments["representation"]!, representationString,
                       "The url query string should not contain the secret")
        // Test secret
        XCTAssertNil(queryArguments["secret"],
                     "The url query string should not contain the secret")

        // Test period
        XCTAssertEqual(queryArguments["period"]!, String(Int(30)),
                       "The period value should be \"30\"")
        // Test counter
        XCTAssertNil(queryArguments["counter"],
                     "The url query string should not contain the counter")

        // Test issuer
        XCTAssertEqual(queryArguments["issuer"]!, issuer,
                       "The issuer value should be \"\(issuer)\"")

        // Check url again
        guard let checkURL = try? token.toURL() else {
            XCTFail("Failed to convert Token to URL")
            return
        }
        XCTAssertEqual(url, checkURL, "Repeated calls to url() should return the same result!")
    }

    func testTokenWithDefaultCounter() {
        let tokenURLString = "otpauth://hotp/bar?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4"
        guard let tokenURL = URL(string: tokenURLString) else {
            XCTFail("Failed to initialize a URL from String \"\(tokenURLString)\"")
            return
        }
        guard let token = Token(url: tokenURL) else {
            XCTFail("Failed to initialize a Token from URL \"\(tokenURL)\"")
            return
        }
        XCTAssertEqual(token.generator.factor, .counter(0))
    }
}
