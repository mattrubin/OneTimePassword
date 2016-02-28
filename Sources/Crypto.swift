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

internal enum Crypto {
    typealias HmacAlgorithm = UInt32

    static let SHA1 = HashFunction(
        ccHmacAlgorithm: UInt32(kCCHmacAlgSHA1),
        digestLength: Int(CC_SHA1_DIGEST_LENGTH)
    )

    static let SHA256 = HashFunction(
        ccHmacAlgorithm: UInt32(kCCHmacAlgSHA256),
        digestLength: Int(CC_SHA256_DIGEST_LENGTH)
    )

    static let SHA512 = HashFunction(
        ccHmacAlgorithm: UInt32(kCCHmacAlgSHA512),
        digestLength: Int(CC_SHA512_DIGEST_LENGTH)
    )

    static func HMAC(hashFunction: HashFunction, key: NSData, data: NSData) -> NSData {
        let hashLength = hashFunction.digestLength

        let macOut = UnsafeMutablePointer<UInt8>.alloc(hashLength)
        defer { macOut.dealloc(hashLength) }

        CCHmac(hashFunction.ccHmacAlgorithm, key.bytes, key.length, data.bytes, data.length, macOut)

        return NSData(bytes: macOut, length: hashLength)
    }
}

internal struct HashFunction {
    private let ccHmacAlgorithm: UInt32
    internal let digestLength: Int
}
