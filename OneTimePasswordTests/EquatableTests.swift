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
        let t0 = Generator.Factor.Timer(30)
        let t1 = Generator.Factor.Timer(60)

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

        XCTAssertEqual(g, Generator(factor: .Counter(0), secret: NSData()))
        XCTAssertNotEqual(g, Generator(factor: .Counter(1), secret: NSData()))
        XCTAssertNotEqual(g, Generator(factor: .Counter(0), secret: "0".dataUsingEncoding(NSUTF8StringEncoding)!))
        XCTAssertNotEqual(g, Generator(factor: .Counter(0), secret: NSData(), algorithm: .SHA256))
        XCTAssertNotEqual(g, Generator(factor: .Counter(0), secret: NSData(), digits: 8))
    }

    func testTokenEquality() {
        let t = Token(name: "Name", issuer: "Issuer", core: Generator(factor: .Counter(0), secret: NSData()))

        XCTAssertEqual(t, Token(name: "Name", issuer: "Issuer", core: Generator(factor: .Counter(0), secret: NSData())))
        XCTAssertNotEqual(t, Token(name: "", issuer: "Issuer", core: Generator(factor: .Counter(0), secret: NSData())))
        XCTAssertNotEqual(t, Token(name: "Name", issuer: "", core: Generator(factor: .Counter(0), secret: NSData())))
        XCTAssertNotEqual(t, Token(name: "Name", issuer: "Issuer", core: Generator(factor: .Counter(1), secret: NSData())))
    }
}
