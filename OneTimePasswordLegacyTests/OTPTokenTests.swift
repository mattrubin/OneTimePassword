//
//  OTPTokenTests.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 2/3/15.
//  Copyright (c) 2015 Matt Rubin. All rights reserved.
//

import XCTest
import OneTimePasswordLegacy

class OTPTokenTests: XCTestCase {
    func testInit() {
        let token = OTPToken()

        XCTAssertEqual(token.name, "")
        XCTAssertEqual(token.issuer, "")
        XCTAssertEqual(token.type, OTPTokenType.Timer)
        XCTAssertEqual(token.secret, NSData())
        XCTAssertEqual(token.algorithm, OTPAlgorithm.SHA1)
        XCTAssertEqual(token.digits, 6)
        XCTAssertEqual(token.period, 30)
        XCTAssertEqual(token.counter, 0)
    }
}
