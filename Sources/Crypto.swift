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

import CommonCrypto

// swiftlint:disable function_parameter_count
// swiftlint:disable variable_name

internal enum Crypto {
    typealias HmacAlgorithm = UInt32

    static let HmacAlgSHA1 = CCHmacAlgorithm(kCCHmacAlgSHA1)
    static let SHA1_DIGEST_LENGTH = Int(CC_SHA1_DIGEST_LENGTH)

    static let HmacAlgSHA256 = CCHmacAlgorithm(kCCHmacAlgSHA256)
    static let SHA256_DIGEST_LENGTH = Int(CC_SHA256_DIGEST_LENGTH)

    static let HmacAlgSHA512 = CCHmacAlgorithm(kCCHmacAlgSHA512)
    static let SHA512_DIGEST_LENGTH = Int(CC_SHA512_DIGEST_LENGTH)

    static func Hmac(algorithm: CCHmacAlgorithm, _ key: UnsafePointer<Void>, _ keyLength: Int, _ data: UnsafePointer<Void>, _ dataLength: Int, _ macOut: UnsafeMutablePointer<Void>) {
        CCHmac(algorithm, key, keyLength, data, dataLength, macOut)
    }
}
