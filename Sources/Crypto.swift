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
    static func HMAC(hashFunction: Generator.Algorithm, key: NSData, data: NSData) -> NSData {
        let hashLength = hashFunction.digestLength

        let macOut = UnsafeMutablePointer<UInt8>.alloc(hashLength)
        defer { macOut.dealloc(hashLength) }

        CCHmac(hashFunction.ccHmacAlgorithm, key.bytes, key.length, data.bytes, data.length, macOut)

        return NSData(bytes: macOut, length: hashLength)
    }
}

extension Generator.Algorithm {
    private var ccHmacAlgorithm: UInt32 {
        switch self {
        case SHA1: return UInt32(kCCHmacAlgSHA1)
        case SHA256: return UInt32(kCCHmacAlgSHA256)
        case SHA512: return UInt32(kCCHmacAlgSHA512)
        }
    }

    private var digestLength: Int {
        switch self {
        case SHA1: return Int(CC_SHA1_DIGEST_LENGTH)
        case SHA256: return Int(CC_SHA256_DIGEST_LENGTH)
        case SHA512: return Int(CC_SHA512_DIGEST_LENGTH)
        }
    }
}
