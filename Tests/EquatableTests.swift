//
//  EquatableTests.swift
//  OneTimePassword
//
//  Copyright (c) 2014-2015 Matt Rubin and the OneTimePassword authors
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
        let g = Generator(factor: .Counter(0), secret: Data(), algorithm: .SHA1, digits: 6)

        XCTAssert(g == Generator(factor: .Counter(0), secret: Data(), algorithm: .SHA1, digits: 6))
        XCTAssert(g != Generator(factor: .Counter(1), secret: Data(), algorithm: .SHA1, digits: 6))
        XCTAssert(g != Generator(factor: .Counter(0), secret: "0".dataUsingEncoding(NSUTF8StringEncoding)!, algorithm: .SHA1, digits: 6))
        XCTAssert(g != Generator(factor: .Counter(0), secret: Data(), algorithm: .SHA256, digits: 6))
        XCTAssert(g != Generator(factor: .Counter(0), secret: Data(), algorithm: .SHA1, digits: 8))
    }

    func testTokenEquality() {
        guard let generator = Generator(factor: .Counter(0), secret: Data(), algorithm: .SHA1, digits: 6),
            let other_generator = Generator(factor: .Counter(1), secret: Data(), algorithm: .SHA512, digits: 8) else {
                XCTFail()
                return
        }

        let t = Token(name: "Name", issuer: "Issuer", generator: generator)

        XCTAssertEqual(t, Token(name: "Name", issuer: "Issuer", generator: generator))
        XCTAssertNotEqual(t, Token(name: "", issuer: "Issuer", generator: generator))
        XCTAssertNotEqual(t, Token(name: "Name", issuer: "", generator: generator))
        XCTAssertNotEqual(t, Token(name: "Name", issuer: "Issuer", generator: other_generator))
    }
}
