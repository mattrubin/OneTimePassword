//
//  TokenSerializationTests.swift
//  OneTimePassword
//
//  Copyright (c) 2014-2022 Matt Rubin and the OneTimePassword authors
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

import Base32
import OneTimePassword
import XCTest

private let validSecret: [UInt8] = [
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
]

// swiftlint:disable:next type_body_length
class TokenSerializationTests: XCTestCase {
    let kOTPScheme = "otpauth"
    let kOTPTokenTypeCounterHost = "hotp"
    let kOTPTokenTypeTimerHost = "totp"
    let kOTPAlgorithmSHA1 = "SHA1"
    let kOTPAlgorithmSHA256 = "SHA256"
    let kOTPAlgorithmSHA512 = "SHA512"

    let factors: [Generator.Factor] = [
        .counter(0),
        .counter(1),
        .counter(.max),
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
    let algorithms: [Generator.Algorithm] = [.sha1, .sha256, .sha512]
    let digits = [6, 7, 8]

    // MARK: mark - Brute Force Tests

    func testDeserialization() throws {
        for factor in factors {
            for name in names {
                for issuer in issuers {
                    for secretString in secretStrings {
                        for algorithm in algorithms {
                            for digitNumber in digits {
                                let secret = secretString.data(using: .ascii)!

                                // Construct the URL
                                var urlComponents = URLComponents()
                                urlComponents.scheme = kOTPScheme
                                urlComponents.host = urlHost(for: factor)
                                urlComponents.path = "/" + name

                                var queryItems: [URLQueryItem] = []
                                let algorithmValue = string(for: algorithm)
                                queryItems.append(URLQueryItem(name: "algorithm", value: algorithmValue))
                                queryItems.append(URLQueryItem(name: "digits", value: String(digitNumber)))
                                let secretValue = MF_Base32Codec.base32String(from: secret)
                                    .replacingOccurrences(of: "=", with: "")
                                queryItems.append(URLQueryItem(name: "secret", value: secretValue))
                                switch factor {
                                case .timer(let period):
                                    let periodValue = String(Int(period))
                                    queryItems.append(URLQueryItem(name: "period", value: periodValue))

                                case .counter(let count):
                                    let counterValue = String(count)
                                    queryItems.append(URLQueryItem(name: "counter", value: counterValue))
                                }
                                queryItems.append(URLQueryItem(name: "issuer", value: issuer))
                                urlComponents.queryItems = queryItems
                                let url = urlComponents.url!

                                // Create the token
                                let token = try Token(url: url)

                                XCTAssertEqual(token.generator.factor, factor, "Incorrect token type")
                                XCTAssertEqual(token.name, name, "Incorrect token name")
                                XCTAssertEqual(token.issuer, issuer, "Incorrect token issuer")
                                XCTAssertEqual(token.generator.secret, secret, "Incorrect token secret")
                                XCTAssertEqual(token.generator.algorithm, algorithm, "Incorrect token algorithm")
                                XCTAssertEqual(token.generator.digits, digitNumber, "Incorrect token digits")
                            }
                        }
                    }
                }
            }
        }
    }

    private func urlHost(for factor: Generator.Factor) -> String {
        switch factor {
        case .counter:
            return kOTPTokenTypeCounterHost
        case .timer:
            return kOTPTokenTypeTimerHost
        }
    }

    private func string(for algorithm: Generator.Algorithm) -> String {
        switch algorithm {
        case .sha1:
            return kOTPAlgorithmSHA1
        case .sha256:
            return kOTPAlgorithmSHA256
        case .sha512:
            return kOTPAlgorithmSHA512
        }
    }

    func testTokenWithURLAndSecret() throws {
        for factor in factors {
            for name in names {
                for issuer in issuers {
                    for secretString in secretStrings {
                        for algorithm in algorithms {
                            for digitNumber in digits {
                                let secret = secretString.data(using: .ascii)!

                                // Construct the URL
                                var urlComponents = URLComponents()
                                urlComponents.scheme = kOTPScheme
                                urlComponents.host = urlHost(for: factor)
                                urlComponents.path = "/" + name

                                var queryItems: [URLQueryItem] = []
                                let algorithmValue = string(for: algorithm)
                                queryItems.append(URLQueryItem(name: "algorithm", value: algorithmValue))
                                queryItems.append(URLQueryItem(name: "digits", value: String(digitNumber)))
                                // TODO: Test secret overriding in a separate test case
                                queryItems.append(URLQueryItem(name: "secret", value: "A"))
                                switch factor {
                                case .timer(let period):
                                    let periodValue = String(Int(period))
                                    queryItems.append(URLQueryItem(name: "period", value: periodValue))

                                case .counter(let count):
                                    let counterValue = String(count)
                                    queryItems.append(URLQueryItem(name: "counter", value: counterValue))
                                }
                                queryItems.append(URLQueryItem(name: "issuer", value: issuer))
                                urlComponents.queryItems = queryItems
                                let url = urlComponents.url!

                                // Create the token
                                let token = try Token(url: url, secret: secret)

                                XCTAssertEqual(token.generator.factor, factor, "Incorrect token type")
                                XCTAssertEqual(token.name, name, "Incorrect token name")
                                XCTAssertEqual(token.issuer, issuer, "Incorrect token issuer")
                                XCTAssertEqual(token.generator.secret, secret, "Incorrect token secret")
                                XCTAssertEqual(token.generator.algorithm, algorithm, "Incorrect token algorithm")
                                XCTAssertEqual(token.generator.digits, digitNumber, "Incorrect token digits")
                            }
                        }
                    }
                }
            }
        }
    }

    // swiftlint:disable:next function_body_length
    func testSerialization() throws {
        for factor in factors {
            for name in names {
                for issuer in issuers {
                    for secretString in secretStrings {
                        for algorithm in algorithms {
                            for digitNumber in digits {
                                // Create the token
                                let generator = try Generator(
                                    factor: factor,
                                    secret: secretString.data(using: .ascii)!,
                                    algorithm: algorithm,
                                    digits: digitNumber
                                )
                                let token = Token(
                                    name: name,
                                    issuer: issuer,
                                    generator: generator
                                )

                                // Serialize
                                let url = try token.toURL()

                                // Test scheme
                                XCTAssertEqual(url.scheme, kOTPScheme, "The url scheme should be \"\(kOTPScheme)\"")
                                // Test Factor
                                let expectedHost = urlHost(for: factor)
                                XCTAssertEqual(url.host, expectedHost, "The url host should be \"\(expectedHost)\"")
                                // Test name
                                XCTAssertEqual(url.path, "/" + name, "The url path should be \"/\(name)\"")

                                let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
                                let queryItems = urlComponents?.queryItems ?? []
                                let expectedItemCount = 4
                                XCTAssertEqual(queryItems.count, expectedItemCount,
                                               "There shouldn't be any unexpected query arguments: \(url)")

                                var queryArguments: [String: String] = [:]
                                for queryItem in queryItems {
                                    XCTAssertNil(queryArguments[queryItem.name])
                                    queryArguments[queryItem.name] = queryItem.value
                                }
                                XCTAssertEqual(queryArguments.count, expectedItemCount,
                                               "There shouldn't be any unexpected query arguments: \(url)")

                                // Test algorithm
                                let expectedAlgorithmString = string(for: algorithm)
                                XCTAssertEqual(queryArguments["algorithm"], expectedAlgorithmString,
                                               "The algorithm value should be \"\(expectedAlgorithmString)\"")

                                // Test digits
                                let expectedDigitsString = String(digitNumber)
                                XCTAssertEqual(queryArguments["digits"], expectedDigitsString,
                                               "The digits value should be \"\(expectedDigitsString)\"")
                                // Test secret
                                XCTAssertNil(queryArguments["secret"],
                                             "The url query string should not contain the secret")

                                // Test period
                                switch factor {
                                case .timer(let period):
                                    let expectedPeriodString = String(Int(period))
                                    XCTAssertEqual(queryArguments["period"], expectedPeriodString,
                                                   "The period value should be \"\(expectedPeriodString)\"")

                                default:
                                    XCTAssertNil(queryArguments["period"],
                                                 "The url query string should not contain the period")
                                }
                                // Test counter
                                switch factor {
                                case .counter(let count):
                                    let expectedCounterString = String(count)
                                    XCTAssertEqual(queryArguments["counter"], expectedCounterString,
                                                   "The counter value should be \"\(expectedCounterString)\"")

                                default:
                                    XCTAssertNil(queryArguments["counter"],
                                                 "The url query string should not contain the counter")
                                }

                                // Test issuer
                                XCTAssertEqual(queryArguments["issuer"], issuer,
                                               "The issuer value should be \"\(issuer)\"")

                                // Check url again
                                let checkURL = try token.toURL()
                                XCTAssertEqual(url, checkURL, "Repeated calls to url() should return the same result!")
                            }
                        }
                    }
                }
            }
        }
    }

    func testTokenWithDefaultCounter() throws {
        let tokenURLString = "otpauth://hotp/bar?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4"
        guard let tokenURL = URL(string: tokenURLString) else {
            XCTFail("Failed to initialize a URL from String \"\(tokenURLString)\"")
            return
        }
        let token = try Token(url: tokenURL)
        XCTAssertEqual(token.generator.factor, .counter(0))
    }

    // MARK: - Test with specific URLs
    // From Google Authenticator for iOS
    // https://code.google.com/p/google-authenticator/source/browse/mobile/ios/Classes/OTPAuthURLTest.m

    // MARK: Deserialization

    func testTokenWithTOTPURL() throws {
        let urlString = "otpauth://totp/L%C3%A9on?algorithm=SHA256&digits=8&period=45&secret=AAAQEAYEAUDAOCAJBIFQYDIOB4"
        let token = try Token(url: URL(string: urlString)!)

        XCTAssertEqual(token.name, "Léon")
        XCTAssertEqual(token.generator.secret, Data(bytes: validSecret, count: validSecret.count))
        XCTAssertEqual(token.generator.factor, Generator.Factor.timer(period: 45))
        XCTAssertEqual(token.generator.algorithm, Generator.Algorithm.sha256)
        XCTAssertEqual(token.generator.digits, 8)
    }

    func testTokenWithHOTPURL() throws {
        let urlString = "otpauth://hotp/L%C3%A9on?algorithm=SHA256&digits=8&counter=18446744073709551615" +
            "&secret=AAAQEAYEAUDAOCAJBIFQYDIOB4"
        let secret = Data(bytes: validSecret, count: validSecret.count)
        let token = try Token(url: URL(string: urlString)!)

        XCTAssertEqual(token.name, "Léon")
        XCTAssertEqual(token.generator.secret, secret)
        XCTAssertEqual(token.generator.factor, Generator.Factor.counter(18446744073709551615))
        XCTAssertEqual(token.generator.algorithm, Generator.Algorithm.sha256)
        XCTAssertEqual(token.generator.digits, 8)
    }

    func testTokenWithInvalidURLs() throws {
        let badURLs = [
            "http://foo",  // invalid scheme
            "otpauth://foo",  // invalid type
            "otpauth:///bar?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4",  // missing type
            "otpauth://totp/bar",  // missing secret
            "otpauth://totp/bar?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4&period=0",  // invalid period
            "otpauth://totp/bar?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4&period=x",  // non-numeric period
            "otpauth://totp/bar?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4&period=30&period=60",  // multiple period
            "otpauth://totp/bar?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4&algorithm=MD5",  // invalid algorithm
            "otpauth://totp/bar?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4&digits=2",  // invalid digits
            "otpauth://totp/bar?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4&digits=x",  // non-numeric digits
            "otpauth://hotp/bar?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4&counter=1.5",  // invalid counter
            "otpauth://hotp/bar?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4&counter=x",  // non-numeric counter
        ]

        for badURL in badURLs {
            let token = try? Token(url: URL(string: badURL)!)
            XCTAssertNil(token, "Invalid url (\(badURL)) generated \(String(describing: token))")
        }
    }

    func testTokenWithIssuer() throws {
        let simpleToken = try Token(url: URL(string: "otpauth://totp/name?secret=A&issuer=issuer")!)
        XCTAssertNotNil(simpleToken)
        XCTAssertEqual(simpleToken.name, "name")
        XCTAssertEqual(simpleToken.issuer, "issuer")

        // TODO: test this more thoroughly, including the override case with
        // "otpauth://totp/_issuer:name?secret=A&isser=issuer"

        let urlStrings = [
            "otpauth://totp/issu%C3%A9r%20!:name?secret=A",
            "otpauth://totp/issu%C3%A9r%20!:%20name?secret=A",
            "otpauth://totp/issu%C3%A9r%20!:%20%20%20name?secret=A",
            "otpauth://totp/issu%C3%A9r%20!%3Aname?secret=A",
            "otpauth://totp/issu%C3%A9r%20!%3A%20name?secret=A",
            "otpauth://totp/issu%C3%A9r%20!%3A%20%20%20name?secret=A",
        ]
        for urlString in urlStrings {
            // If there is no issuer argument, extract the issuer from the name
            let token = try Token(url: URL(string: urlString)!)

            XCTAssertNotNil(token, "<\(urlString)> did not create a valid token.")
            XCTAssertEqual(token.name, "name")
            XCTAssertEqual(token.issuer, "issuér !")

            // If there is an issuer argument which matches the one in the name, trim the name
            let token2 = try Token(url: URL(string: urlString.appending("&issuer=issu%C3%A9r%20!"))!)

            XCTAssertNotNil(token2, "<\(urlString)> did not create a valid token.")
            XCTAssertEqual(token2.name, "name")
            XCTAssertEqual(token2.issuer, "issuér !")

            // If there is an issuer argument different from the name prefix,
            // trust the argument and leave the name as it is
            let token3 = try Token(url: URL(string: urlString.appending("&issuer=test"))!)

            XCTAssertNotNil(token3, "<\(urlString)> did not create a valid token.")
            XCTAssertNotEqual(token3.name, "name")
            XCTAssertTrue(token3.name.hasPrefix("issuér !"), "The name should begin with \"issuér !\"")
            XCTAssertTrue(token3.name.hasSuffix("name"), "The name should end with \"name\"")
            XCTAssertEqual(token3.issuer, "test")
        }
    }

    // MARK: Serialization

    func testTOTPURL() throws {
        let secret = MF_Base32Codec.data(fromBase32String: "AAAQEAYEAUDAOCAJBIFQYDIOB4")!
        let generator = try Generator(factor: .timer(period: 45), secret: secret, algorithm: .sha256, digits: 8)
        let token = Token(name: "Léon", generator: generator)

        // swiftlint:disable:next force_try
        let url = try! token.toURL()

        XCTAssertEqual(url.scheme, "otpauth")
        XCTAssertEqual(url.host, "totp")
        XCTAssertEqual(url.path, "/Léon")

        let expectedQueryItems = [
            URLQueryItem(name: "algorithm", value: "SHA256"),
            URLQueryItem(name: "digits", value: "8"),
            URLQueryItem(name: "issuer", value: ""),
            URLQueryItem(name: "period", value: "45"),
        ]
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        XCTAssertEqual(queryItems, expectedQueryItems)
    }

    func testHOTPURL() throws {
        let secret = MF_Base32Codec.data(fromBase32String: "AAAQEAYEAUDAOCAJBIFQYDIOB4")!
        let generator = try Generator(
            factor: .counter(18446744073709551615),
            secret: secret,
            algorithm: .sha256,
            digits: 8)
        let token = Token(name: "Léon", generator: generator)

        // swiftlint:disable:next force_try
        let url = try! token.toURL()

        XCTAssertEqual(url.scheme, "otpauth")
        XCTAssertEqual(url.host, "hotp")
        XCTAssertEqual(url.path, "/Léon")

        let expectedQueryItems = [
            URLQueryItem(name: "algorithm", value: "SHA256"),
            URLQueryItem(name: "digits", value: "8"),
            URLQueryItem(name: "issuer", value: ""),
            URLQueryItem(name: "counter", value: "18446744073709551615"),
        ]
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        XCTAssertEqual(queryItems, expectedQueryItems)
    }
}

// swiftlint:disable:this file_length
