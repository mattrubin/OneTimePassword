//
//  Crypto.swift
//  OneTimePassword
//
//  Copyright (c) 2016 Matt Rubin and the OneTimePassword authors
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

import Foundation
import CommonCrypto

// swiftlint:disable function_parameter_count
// swiftlint:disable variable_name

internal enum Crypto {
    typealias HmacAlgorithm = UInt32

    static let SHA1 = HashFunction(
        CCHmacAlgorithm: UInt32(kCCHmacAlgSHA1),
        digestLength: Int(CC_SHA1_DIGEST_LENGTH)
    )

    static let SHA256 = HashFunction(
        CCHmacAlgorithm: UInt32(kCCHmacAlgSHA256),
        digestLength: Int(CC_SHA256_DIGEST_LENGTH)
    )

    static let SHA512 = HashFunction(
        CCHmacAlgorithm: UInt32(kCCHmacAlgSHA512),
        digestLength: Int(CC_SHA512_DIGEST_LENGTH)
    )

    static func HMAC(hashFunction: HashFunction, key: NSData, data: NSData, _ macOut: UnsafeMutablePointer<Void>) {
        let algorithm = hashFunction.CCHmacAlgorithm
        CCHmac(algorithm, key.bytes, key.length, data.bytes, data.length, macOut)
    }
}

internal struct HashFunction {
    private let CCHmacAlgorithm: UInt32
    internal let digestLength: Int
}
