//
//  EquatableTests.swift
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

class EquatableTests: XCTestCase {
    func testFactorEquality() {
        let smallCounter = Generator.Factor.counter(30)
        let bigCounter = Generator.Factor.counter(60)
        let shortTimer = Generator.Factor.timer(period: 30)
        let longTimer = Generator.Factor.timer(period: 60)

        XCTAssertEqual(smallCounter, smallCounter)
        XCTAssertEqual(bigCounter, bigCounter)
        XCTAssertNotEqual(smallCounter, bigCounter)
        XCTAssertNotEqual(bigCounter, smallCounter)

        XCTAssertEqual(shortTimer, shortTimer)
        XCTAssertEqual(longTimer, longTimer)
        XCTAssertNotEqual(shortTimer, longTimer)
        XCTAssertNotEqual(longTimer, shortTimer)

        XCTAssertNotEqual(smallCounter, shortTimer)
        XCTAssertNotEqual(smallCounter, longTimer)
        XCTAssertNotEqual(bigCounter, shortTimer)
        XCTAssertNotEqual(bigCounter, longTimer)

        XCTAssertNotEqual(shortTimer, smallCounter)
        XCTAssertNotEqual(shortTimer, bigCounter)
        XCTAssertNotEqual(longTimer, smallCounter)
        XCTAssertNotEqual(longTimer, bigCounter)
    }

    func testGeneratorEquality() {
        let generator = Generator(factor: .counter(0), secret: Data(), algorithm: .sha1, digits: 6)
        let badData = "0".data(using: String.Encoding.utf8)!

        XCTAssert(generator == Generator(factor: .counter(0), secret: Data(), algorithm: .sha1, digits: 6))
        XCTAssert(generator != Generator(factor: .counter(1), secret: Data(), algorithm: .sha1, digits: 6))
        XCTAssert(generator != Generator(factor: .counter(0), secret: badData, algorithm: .sha1, digits: 6))
        XCTAssert(generator != Generator(factor: .counter(0), secret: Data(), algorithm: .sha256, digits: 6))
        XCTAssert(generator != Generator(factor: .counter(0), secret: Data(), algorithm: .sha1, digits: 8))
    }

    func testTokenEquality() {
        guard let generator = Generator(factor: .counter(0), secret: Data(), algorithm: .sha1, digits: 6),
            let otherGenerator = Generator(factor: .counter(1), secret: Data(), algorithm: .sha512, digits: 8) else {
                XCTFail("Failed to construct Generator.")
                return
        }

        let token = Token(name: "Name", issuer: "Issuer", generator: generator)

        XCTAssertEqual(token, Token(name: "Name", issuer: "Issuer", generator: generator))
        XCTAssertNotEqual(token, Token(name: "", issuer: "Issuer", generator: generator))
        XCTAssertNotEqual(token, Token(name: "Name", issuer: "", generator: generator))
        XCTAssertNotEqual(token, Token(name: "Name", issuer: "Issuer", generator: otherGenerator))
    }
}
