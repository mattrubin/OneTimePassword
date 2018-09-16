//
//  Crypto.swift
//  OneTimePassword
//
//  Copyright (c) 2016-2017 Matt Rubin and the OneTimePassword authors
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
#if swift(>=4.1)
    #if canImport(CommonCrypto)
        import CommonCrypto
    #else
        import CommonCryptoShim
    #endif
#else
    import CommonCryptoShim
#endif

func HMAC(algorithm: Generator.Algorithm, key: Data, data: Data) -> Data {
    let (hashFunction, hashLength) = algorithm.hashInfo

    let macOut = UnsafeMutablePointer<UInt8>.allocate(capacity: hashLength)
    defer {
        #if swift(>=4.1)
        macOut.deallocate()
        #else
        macOut.deallocate(capacity: hashLength)
        #endif
    }

    key.withUnsafeBytes { keyBytes in
        data.withUnsafeBytes { dataBytes in
            CCHmac(hashFunction, keyBytes, key.count, dataBytes, data.count, macOut)
        }
    }

    return Data(bytes: macOut, count: hashLength)
}

private extension Generator.Algorithm {
    /// The corresponding CommonCrypto hash function and hash length.
    var hashInfo: (hashFunction: CCHmacAlgorithm, hashLength: Int) {
        switch self {
        case .sha1:
            return (CCHmacAlgorithm(kCCHmacAlgSHA1), Int(CC_SHA1_DIGEST_LENGTH))
        case .sha256:
            return (CCHmacAlgorithm(kCCHmacAlgSHA256), Int(CC_SHA256_DIGEST_LENGTH))
        case .sha512:
            return (CCHmacAlgorithm(kCCHmacAlgSHA512), Int(CC_SHA512_DIGEST_LENGTH))
        }
    }
}
