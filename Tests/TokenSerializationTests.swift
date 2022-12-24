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

import Base32
import OneTimePassword
import XCTest

private let validSecret: [UInt8] = [
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
]

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
                                    secret: secretString.data(using: String.Encoding.ascii)!,
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
                                let expectedItemCount = 4
                                XCTAssertEqual(items?.count, expectedItemCount,
                                               "There shouldn't be any unexpected query arguments: \(url)")

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
