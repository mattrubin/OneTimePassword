//
//  OTPTokenSerializationTests.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 6/10/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import XCTest
import OneTimePassword


let kOTPScheme = "otpauth";
let kOTPTokenTypeCounterHost = "hotp";
let kOTPTokenTypeTimerHost   = "totp";

let types: Token.TokenType[] = [.Counter, .Timer];
let names = ["", "Login", "user_123@website.com", "Léon", ":/?#[]@!$&'()*+,;=%\""];
let issuers = ["", "Big Cörpøráçìôn", ":/?#[]@!$&'()*+,;=%\""];
let secretStrings = ["12345678901234567890", "12345678901234567890123456789012", "1234567890123456789012345678901234567890123456789012345678901234", ""];
let algorithms: Token.Algorithm[] = [.SHA1, .SHA256, .SHA512];
let digits = [6, 7, 8];
let periods: NSTimeInterval[] = [0, 1, 30];
let counters: UInt64[] = [0, 1, 18_446_744_073_709_551_615];


class OTPTokenSerializationTests: XCTestCase {

    func testSerialization() {
        for type in types {
            for name in names {
                for issuer in issuers {
                    for secretString in secretStrings {
                        for algorithm in algorithms {
                            for digitNumber in digits {
                                for period in periods {
                                    for counter in counters {
                                        // Create the token
                                        let token = Token(type: type, secret:secretString.dataUsingEncoding(NSASCIIStringEncoding), name:name, issuer:issuer, algorithm:algorithm, digits:digitNumber, period: period, counter: counter)

                                        // Serialize
                                        let url = token.url();

                                        // Test scheme
                                        XCTAssertEqualObjects(url.scheme, kOTPScheme, "The url scheme should be \"\(kOTPScheme)\"");
                                        // Test type
                                        let expectedHost = (type == .Counter) ? kOTPTokenTypeCounterHost : kOTPTokenTypeTimerHost;
                                        XCTAssertEqualObjects(url.host, expectedHost, "The url host should be \"\(expectedHost)\"");
                                        // Test name
                                        XCTAssertEqualObjects(url.path.substringFromIndex(1), name, "The url path should be \"\(name)\"");

                                        var urlComponents = NSURLComponents(URL:url, resolvingAgainstBaseURL:false)
                                        var items = urlComponents.queryItems as NSURLQueryItem[]
                                        XCTAssertEqual(items.count, 4, "There shouldn't be any unexpected query arguments");

                                        var queryArguments = Dictionary<String, String>()
                                        for item in items {
                                            queryArguments[item.name] = item.value
                                        }
                                        XCTAssertEqual(queryArguments.count, 4, "There shouldn't be any unexpected query arguments");

                                        // Test algorithm
                                        XCTAssertEqualObjects(queryArguments["algorithm"], algorithm.toRaw(), "The algorithm value should be \"\(algorithm.toRaw())\"");
                                        // Test digits
                                        XCTAssertEqualObjects(queryArguments["digits"], String(digitNumber), "The digits value should be \"\(digitNumber)\"");
                                        // Test secret
                                        XCTAssertNil(queryArguments["secret"], "The url query string should not contain the secret");

                                        // Test period
                                        if type == .Timer {
                                            XCTAssertEqualObjects(queryArguments["period"], String(Int(period)), "The period value should be \"\(period)\"");
                                        } else {
                                            XCTAssertNil(queryArguments["period"], "The url query string should not contain the period");
                                        }
                                        // Test counter
                                        if (type == .Counter) {
                                            XCTAssertEqualObjects(queryArguments["counter"], String(counter), "The counter value should be \"\(counter)\"");
                                        } else {
                                            XCTAssertNil(queryArguments["counter"], "The url query string should not contain the counter");
                                        }

                                        // Test issuer
                                        XCTAssertEqualObjects(queryArguments["issuer"], issuer, "The issuer value should be \"\(issuer)\"");

                                        // Check url again
                                        let checkURL = token.url();
                                        XCTAssertEqualObjects(url, checkURL, "Repeated calls to url() should return the same result!");
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
