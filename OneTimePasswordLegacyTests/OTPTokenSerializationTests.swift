//
//  OTPTokenSerializationTests.swift
//  OneTimePasswordLegacyTests
//
//  Created by Andreas Osberghaus on 18.12.20.
//  Copyright © 2020 Matt Rubin. All rights reserved.
//

import XCTest
import Base32

private let kOTPScheme = "otpauth"
private let kOTPTokenTypeCounterHost = "hotp"
private let kOTPTokenTypeTimerHost = "totp"
private let kRandomKey = "RANDOM"

private var types: [OTPTokenType] = []
private var names: [String] = []
private var issuers: [String] = []
private var secrets: [String] = []
private var algorithms: [OTPAlgorithm] = []
private var digits: [UInt] = []
private var periods: [Double] = []
private var counters: [UInt64] = []

private let kValidSecret: [CUnsignedChar] = [
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
    0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f
]

// swiftlint:disable:next type_body_length
class OTPTokenSerializationTests: XCTestCase {
    override class func setUp() {
        super.setUp()

        types = [OTPTokenType.counter, OTPTokenType.timer]
        names = [
            "",
            "Login",
            "user123@website.com",
            "Léon",
            ":/?#[]@!$&'()*+,;=%\""
        ]
        issuers = ["", "Big Cörpøráçìôn", ":/?#[]@!$&'()*+,;=%\""]
        secrets = [
            "12345678901234567890",
            "12345678901234567890123456789012",
            "1234567890123456789012345678901234567890123456789012345678901234",
            ""
        ]
        algorithms = [OTPAlgorithm.sha1, OTPAlgorithm.sha256, OTPAlgorithm.sha512]
        digits = [0, 6, 8]
        periods = [0, 1, 30, Double.random(in: 1...300)]
        counters = [0, 1, 99999, UInt64.random(in: UInt64.min...UInt64.max) << 32]
    }

    // swiftlint:disable line_length function_body_length cyclomatic_complexity
    func testDeserialization() throws {
        for type in types {
            for name in names {
                for issuer in issuers {
                    for secret in secrets {
                        for algorithm in algorithms {
                            for digit in digits {
                                for period in periods {
                                    for counter in counters {
                                        let urlComponents = NSURLComponents()
                                        urlComponents.scheme = kOTPScheme
                                        urlComponents.host = type.stringValue
                                        urlComponents.path = "/" + name
                                        urlComponents.queryItems = [
                                            .init(name: "algorithm", value: "\(algorithm.stringValue)"),
                                            .init(name: "digits", value: "\(digit)"),
                                            .init(name: "secret", value: secret
                                                    .data(using: .ascii)!
                                                    .base32EncodedString
                                                    .replacingOccurrences(of: "=", with: "")
                                            ),
                                            .init(name: "period", value: "\(period)"),
                                            .init(name: "counter", value: "\(counter)"),
                                            .init(name: "issuer", value: issuer)
                                        ]
                                        if let url = urlComponents.url, let token = OTPToken.token(from: url) {
                                            XCTAssertEqual(token.type, type, "Incorrect token type")
                                            XCTAssertEqual(token.name, name, "Incorrect token name")
                                            XCTAssertEqual(token.name, name, "Incorrect token name")
                                            XCTAssertEqual(token.issuer, issuer, "Incorrect token issuer")
                                            XCTAssertEqual(token.secret, secret.data(using: .ascii), "Incorrect token secret")
                                            XCTAssertEqual(token.algorithm, algorithm, "Incorrect token algorithm")
                                            XCTAssertEqual(token.digits, digit, "Incorrect token digits")
                                            switch token.type {
                                            case .timer:
                                                XCTAssertTrue(abs(token.period - period) < Double.ulpOfOne, "Incorrect token period")
                                            case .counter:
                                                XCTAssertEqual(token.counter, counter, "Incorrect token counter")
                                            }
                                        } else {
                                            // If nil was returned from [OTPToken tokenWithURL:], create the same token manually and ensure it's invalid
                                            let invalidToken = OTPToken()
                                            invalidToken.type = type
                                            invalidToken.name = name
                                            invalidToken.issuer = issuer
                                            invalidToken.secret = secret.data(using: .ascii)!
                                            invalidToken.algorithm = algorithm
                                            invalidToken.digits = digit
                                            invalidToken.period = period
                                            invalidToken.counter = counter

                                            XCTAssertFalse(invalidToken.validate(), "The token should be invalid")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    // swiftlint:enable line_length function_body_length cyclomatic_complexity

    // swiftlint:disable line_length function_body_length cyclomatic_complexity
    func testTokenWithURLAndSecret() throws {
        for type in types {
            for name in names {
                for issuer in issuers {
                    for secret in secrets {
                        for algorithm in algorithms {
                            for digit in digits {
                                for period in periods {
                                    for counter in counters {
                                        let urlComponents = NSURLComponents()
                                        urlComponents.scheme = kOTPScheme
                                        urlComponents.host = type.stringValue
                                        urlComponents.path = "/" + name
                                        urlComponents.queryItems = [
                                            .init(name: "algorithm", value: "\(algorithm.stringValue)"),
                                            .init(name: "digits", value: "\(digit)"),
                                            .init(name: "secret", value: "A"),
                                            .init(name: "period", value: "\(period)"),
                                            .init(name: "counter", value: "\(counter)"),
                                            .init(name: "issuer", value: issuer)
                                        ]

                                        if let url = urlComponents.url,
                                           let token = OTPToken.token(from: url, secret: secret.data(using: .ascii)) {
                                            XCTAssertEqual(token.type, type, "Incorrect token type")
                                            XCTAssertEqual(token.name, name, "Incorrect token name")
                                            XCTAssertEqual(token.name, name, "Incorrect token name")
                                            XCTAssertEqual(token.issuer, issuer, "Incorrect token issuer")
                                            XCTAssertEqual(token.secret, secret.data(using: .ascii), "Incorrect token secret")
                                            XCTAssertEqual(token.algorithm, algorithm, "Incorrect token algorithm")
                                            XCTAssertEqual(token.digits, digit, "Incorrect token digits")
                                            switch token.type {
                                            case .timer:
                                                XCTAssertTrue(abs(token.period - period) < Double.ulpOfOne, "Incorrect token period")
                                            case .counter:
                                                XCTAssertEqual(token.counter, counter, "Incorrect token counter")
                                            }
                                        } else {
                                            // If nil was returned from [OTPToken tokenWithURL:], create the same token manually and ensure it's invalid
                                            let invalidToken = OTPToken()
                                            invalidToken.type = type
                                            invalidToken.name = name
                                            invalidToken.issuer = issuer
                                            invalidToken.secret = secret.data(using: .ascii)!
                                            invalidToken.algorithm = algorithm
                                            invalidToken.digits = digit
                                            invalidToken.period = period
                                            invalidToken.counter = counter

                                            XCTAssertFalse(invalidToken.validate(), "The token should be invalid")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    // swiftlint:enable line_length function_body_length cyclomatic_complexity

    // swiftlint:disable line_length function_body_length cyclomatic_complexity
    func testSerialization() throws {
        for type in types {
            for name in names {
                for issuer in issuers {
                    for secret in secrets {
                        for algorithm in algorithms {
                            for digit in digits {
                                for period in periods {
                                    for counter in counters {
                                        let token = OTPToken()
                                        token.type = type
                                        token.type = type
                                        token.name = name
                                        token.issuer = issuer
                                        token.secret = secret.data(using: .ascii)!
                                        token.algorithm = algorithm
                                        token.digits = digit
                                        token.period = period
                                        token.counter = counter

                                        // An invalid token should not (cannot) produce a URL
                                        guard let url = token.url(), !token.validate() else {
                                            continue
                                        }

                                        XCTAssertEqual(url.scheme, kOTPScheme, "The url scheme should be \(kOTPScheme)")
                                        XCTAssertEqual(url.host, type.stringValue, "The url host should be \(type.stringValue)")

                                        if !name.isEmpty {
                                            XCTAssertEqual((url.path as NSString).substring(from: 1), name, "The url path should be \(name)")
                                        } else {
                                            XCTAssertEqual(url.path, "", "The url path should be empty")
                                        }

                                        let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
                                        guard let queryItems = urlComponents?.queryItems else {
                                            XCTFail("Queryitems shouldn't be nil")
                                            continue
                                        }

                                        let queryArguments = queryItems.reduce(into: [String: String]()) {
                                            XCTAssertNil($0[$1.name])
                                            $0[$1.name] = $1.value
                                        }

                                        XCTAssertEqual(queryArguments["algorithm"], algorithm.stringValue, "The algorithm value should be \(algorithm.stringValue)")
                                        XCTAssertEqual(queryArguments["digits"], "\(digit)", "The digits value should be \(digit)")
                                        XCTAssertNil(queryArguments["secret"], "The url query string should not contain the secret")

                                        switch type {
                                        case .timer:
                                            XCTAssertEqual(queryArguments["period"], type.stringValue, "The period value should be \(type.stringValue)")
                                            XCTAssertNil(queryArguments["counter"])
                                        case .counter:
                                            XCTAssertEqual(queryArguments["counter"], type.stringValue, "The counter value should be \(type.stringValue)")
                                            XCTAssertNil(queryArguments["period"])
                                        }

                                        XCTAssertEqual(queryArguments["issuer"], issuer, "The issuer value should be \(issuer)")
                                        XCTAssertEqual(queryArguments.count, issuer.isEmpty ? 3 : 4, "There shouldn't be any unexpected query arguments")

                                        XCTAssertEqual(url, token.url(), "Repeated calls to url() should return the same result!")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    // swiftlint:enable line_length function_body_length cyclomatic_complexity

    func testTokenWithTOTPURL() throws {
        let secret = Data(bytes: kValidSecret, count: MemoryLayout.size(ofValue: kValidSecret) * 2)
        // swiftlint:disable:next line_length
        let url = URL(string: "otpauth://totp/L%C3%A9on?algorithm=SHA256&digits=8&period=45&secret=AAAQEAYEAUDAOCAJBIFQYDIOB4")!
        let token = OTPToken.token(from: url, secret: nil)!

        XCTAssertEqual(token.name, "Léon")
        XCTAssertEqual(token.secret.base32EncodedString, secret.base32EncodedString)
        XCTAssertEqual(token.type, OTPTokenType.timer)
        XCTAssertEqual(token.algorithm, OTPAlgorithm.sha256)
        XCTAssertTrue(abs(token.period - 45.0) < Double.ulpOfOne)
        XCTAssertEqual(token.digits, 8)
    }

    func testTokenWithHOTPURL() throws {
        let secret = Data(bytes: kValidSecret, count: MemoryLayout.size(ofValue: kValidSecret) * 2)
        // swiftlint:disable:next line_length
        let url = URL(string: "otpauth://hotp/L%C3%A9on?algorithm=SHA256&digits=8&counter=18446744073709551615&secret=AAAQEAYEAUDAOCAJBIFQYDIOB4")!
        let token = OTPToken.token(from: url, secret: nil)!

        XCTAssertEqual(token.name, "Léon")
        XCTAssertEqual(token.secret, secret)
        XCTAssertEqual(token.type, OTPTokenType.counter)
        XCTAssertEqual(token.algorithm, OTPAlgorithm.sha256)
        XCTAssertEqual(token.counter, 18446744073709551615)
        XCTAssertEqual(token.digits, 8)
    }

    func testTokenWithInvalidURLS() throws {
        let badURLs: [String] = [
            "http://foo" /* invalid scheme */,
            "otpauth://foo" /* invalid type */,
            "otpauth:///bar?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4" /* missing type */,
            "otpauth://totp/bar" /* missing secret */,
            "otpauth://totp/bar?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4&period=0" /* invalid period */,
            "otpauth://totp/bar?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4&period=x" /* non-numeric period */,
            "otpauth://totp/bar?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4&period=30&period=60" /* multiple period */,
            "otpauth://totp/bar?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4&algorithm=MD5" /* invalid algorithm */,
            "otpauth://totp/bar?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4&digits=2" /* invalid digits */,
            "otpauth://totp/bar?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4&digits=x" /* non-numeric digits */,
            "otpauth://hotp/bar?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4&counter=1.5" /* invalid counter */,
            "otpauth://hotp/bar?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4&counter=x", // non-numeric counter
            "otpauth://hotp/bar?secret=a&counter=18446744073709551615" // invalid secret
        ]
        for badURL in badURLs {
            let url = URL(string: badURL)!
            let token = OTPToken.token(from: url)
            XCTAssertNil(token, "Invalid url (\(badURL)) generated \(String(describing: token))")
        }
    }

    func testTokenWithIssuer() throws {
        let url = URL(string: "otpauth://totp/name?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4&issuer=issuer")!
        let simpleToken = OTPToken.token(from: url)!
        XCTAssertEqual(simpleToken.name, "name")
        XCTAssertEqual(simpleToken.issuer, "issuer")

        let urlStrings: [String] = [
            "otpauth://totp/issu%C3%A9r%20!:name?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4",
            "otpauth://totp/issu%C3%A9r%20!:%20name?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4",
            "otpauth://totp/issu%C3%A9r%20!:%20%20%20name?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4",
            "otpauth://totp/issu%C3%A9r%20!%3Aname?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4",
            "otpauth://totp/issu%C3%A9r%20!%3A%20name?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4",
            "otpauth://totp/issu%C3%A9r%20!%3A%20%20%20name?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4"
        ]

        for urlString in urlStrings {
            let url = URL(string: urlString)!
            let token = OTPToken.token(from: url)!

            XCTAssertEqual(token.name, "name")
            XCTAssertEqual(token.issuer, "issuér !")

            // If there is an issuer argument which matches the one in the name, trim the name
            let urlString2 = urlString.appending("&issuer=issu%C3%A9r%20!")
            let url2 = URL(string: urlString2)!
            let token2 = OTPToken.token(from: url2)!

            XCTAssertEqual(token2.name, "name")
            XCTAssertEqual(token2.issuer, "issuér !")

            // If there is an issuer argument different from the name prefix,
            // trust the argument and leave the name as it is

            let urlString3 = urlString.appending("&issuer=test")
            let url3 = URL(string: urlString3)!
            let token3 = OTPToken.token(from: url3)!

            XCTAssertNotEqual(token3.name, "name")
            XCTAssertTrue(token3.name.starts(with: "issuér !"))
            XCTAssertTrue(token3.name.hasSuffix("name"))
            XCTAssertEqual(token3.issuer, "test")
        }
    }

    func testTOTPURL() throws {
        // swiftlint:disable:next line_length
        let url = URL(string: "otpauth://totp/L%C3%A9on?algorithm=SHA256&digits=8&period=45&secret=AAAQEAYEAUDAOCAJBIFQYDIOB4")!
        let token = OTPToken.token(from: url)!

        let tokenURL = token.url()!

        XCTAssertEqual(tokenURL.scheme, "otpauth")
        XCTAssertEqual(tokenURL.host, "totp")
        XCTAssertEqual(url.pathComponents[1], "Léon")

        let expectedQueryItems: [URLQueryItem] = [
            .init(name: "algorithm", value: "SHA256"),
            .init(name: "digits", value: "8"),
            .init(name: "issuer", value: ""),
            .init(name: "period", value: "45")
        ]
        let queryItems = URLComponents(url: tokenURL, resolvingAgainstBaseURL: false)?.queryItems
        XCTAssertEqual(queryItems, expectedQueryItems)
    }

    func testHOTPURL() throws {
        // swiftlint:disable:next line_length
        let url = URL(string: "otpauth://hotp/L%C3%A9on?algorithm=SHA256&digits=8&counter=18446744073709551615&secret=AAAQEAYEAUDAOCAJBIFQYDIOB4")!
        let token = OTPToken.token(from: url)!

        let tokenURL = token.url()!

        XCTAssertEqual(tokenURL.scheme, "otpauth")
        XCTAssertEqual(tokenURL.host, "hotp")
        XCTAssertEqual(url.pathComponents[1], "Léon")

        let expectedQueryItems: [URLQueryItem] = [
            .init(name: "algorithm", value: "SHA256"),
            .init(name: "digits", value: "8"),
            .init(name: "issuer", value: ""),
            .init(name: "counter", value: "18446744073709551615")
        ]
        let queryItems = URLComponents(url: tokenURL, resolvingAgainstBaseURL: false)?.queryItems
        XCTAssertEqual(queryItems, expectedQueryItems)
    }
}
