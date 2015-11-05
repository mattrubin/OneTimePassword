//
//  EquatableTests.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 8/12/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import XCTest
import OneTimePassword

class EquatableTests: XCTestCase {
    func testFactorEquality() {
        let c0 = Generator.Factor.Counter(30)
        let c1 = Generator.Factor.Counter(60)
        let t0 = Generator.Factor.Timer(period: 30)
        let t1 = Generator.Factor.Timer(period: 60)

        XCTAssertEqual(c0, c0)
        XCTAssertEqual(c1, c1)
        XCTAssertNotEqual(c0, c1)
        XCTAssertNotEqual(c1, c0)

        XCTAssertEqual(t0, t0)
        XCTAssertEqual(t1, t1)
        XCTAssertNotEqual(t0, t1)
        XCTAssertNotEqual(t1, t0)

        XCTAssertNotEqual(c0, t0)
        XCTAssertNotEqual(c0, t1)
        XCTAssertNotEqual(c1, t0)
        XCTAssertNotEqual(c1, t1)

        XCTAssertNotEqual(t0, c0)
        XCTAssertNotEqual(t0, c1)
        XCTAssertNotEqual(t1, c0)
        XCTAssertNotEqual(t1, c1)
    }

    func testGeneratorEquality() {
        let g = Generator(factor: .Counter(0), secret: NSData(), algorithm: .SHA1, digits: 6)

        XCTAssert(g == Generator(factor: .Counter(0), secret: NSData()))
        XCTAssert(g != Generator(factor: .Counter(1), secret: NSData()))
        XCTAssert(g != Generator(factor: .Counter(0), secret: "0".dataUsingEncoding(NSUTF8StringEncoding)!))
        XCTAssert(g != Generator(factor: .Counter(0), secret: NSData(), algorithm: .SHA256))
        XCTAssert(g != Generator(factor: .Counter(0), secret: NSData(), digits: 8))
    }

    func testTokenEquality() {
        let generator = Generator(factor: .Counter(0), secret: NSData())
        let other_generator = Generator(factor: .Counter(1), secret: NSData())

        let t = Token(name: "Name", issuer: "Issuer", core: generator)

        XCTAssertEqual(t, Token(name: "Name", issuer: "Issuer", core: generator))
        XCTAssertNotEqual(t, Token(name: "", issuer: "Issuer", core: generator))
        XCTAssertNotEqual(t, Token(name: "Name", issuer: "", core: generator))
        XCTAssertNotEqual(t, Token(name: "Name", issuer: "Issuer", core: other_generator))
    }
}
