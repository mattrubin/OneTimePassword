//
//  Crypto.swift
//  OneTimePassword
//
//  Copyright (c) 2016-2018 Matt Rubin and the OneTimePassword authors
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
#if canImport(CryptoKit)
import CryptoKit
#endif

#if canImport(CryptoKit)
func HMAC(algorithm: Generator.Algorithm, key: Data, data: Data) -> Data {
    if #available(iOS 13.0, macOS 10.15, watchOS 6.0, *) {
        let key = SymmetricKey(data: key)

        func createData(_ ptr: UnsafeRawBufferPointer) -> Data {
            Data(bytes: ptr.baseAddress!, count: algorithm.hashLength)
        }

        switch algorithm {
        case .sha1:
            return CryptoKit.HMAC<Insecure.SHA1>.authenticationCode(for: data, using: key).withUnsafeBytes(createData)
        case .sha256:
            return CryptoKit.HMAC<SHA256>.authenticationCode(for: data, using: key).withUnsafeBytes(createData)
        case .sha512:
            return CryptoKit.HMAC<SHA512>.authenticationCode(for: data, using: key).withUnsafeBytes(createData)
        }
    } else {
        return legacyHMAC(algorithm: algorithm, key: key, data: data)
    }
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0, *)
private extension Generator.Algorithm {
    var hashLength: Int {
        switch self {
        case .sha1:
            return Insecure.SHA1.byteCount
        case .sha256:
            return SHA256.byteCount
        case .sha512:
            return SHA512.byteCount
        }
    }
}
#else
func HMAC(algorithm: Generator.Algorithm, key: Data, data: Data) -> Data {
    return legacyHMAC(algorithm: algorithm, key: key, data: data)
}
#endif

func legacyHMAC(algorithm: Generator.Algorithm, key: Data, data: Data) -> Data {
    let (hashFunction, hashLength) = algorithm.hashInfo

    let macOut = UnsafeMutablePointer<UInt8>.allocate(capacity: hashLength)

    defer {
        macOut.deallocate()
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
