//
//  GeneratorFunctions.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 8/25/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import Foundation
import CommonCrypto

internal enum GenerationError: ErrorType {
    case InvalidTime
    case InvalidPeriod
    case InvalidDigits
}

func validateDigits(digits: Int) throws {
    // https://tools.ietf.org/html/rfc4226#section-5.3
    // "Implementations MUST extract a 6-digit code at a minimum and possibly 7 and 8-digit codes."
    let acceptableDigits = 6...8
    guard acceptableDigits.contains(digits) else {
        throw GenerationError.InvalidDigits
    }
}

internal func counterForGeneratorWithFactor(factor: Generator.Factor, atTimeIntervalSince1970 timeInterval: NSTimeInterval) throws -> UInt64 {
    switch factor {
    case .Counter(let counter):
        return counter
    case .Timer(let period):
        // The time interval must be positive to produce a valid counter value.
        guard timeInterval >= 0 else {
            throw GenerationError.InvalidTime
        }
        // The period must be positive and non-zero to produce a valid counter value.
        guard period > 0 else {
            throw GenerationError.InvalidPeriod
        }
        return UInt64(timeInterval / period)
    }
}

internal func generatePassword(algorithm algorithm: Generator.Algorithm, digits: Int, secret: NSData, counter: UInt64) throws -> String {
    try validateDigits(digits)

    func hashInfoForAlgorithm(algorithm: Generator.Algorithm) -> (algorithm: CCHmacAlgorithm, length: Int) {
        switch algorithm {
        case .SHA1:
            return (CCHmacAlgorithm(kCCHmacAlgSHA1), Int(CC_SHA1_DIGEST_LENGTH))
        case .SHA256:
            return (CCHmacAlgorithm(kCCHmacAlgSHA256), Int(CC_SHA256_DIGEST_LENGTH))
        case .SHA512:
            return (CCHmacAlgorithm(kCCHmacAlgSHA512), Int(CC_SHA512_DIGEST_LENGTH))
        }
    }

    // Ensure the counter value is big-endian
    var bigCounter = counter.bigEndian

    // Generate an HMAC value from the key and counter
    let (hashAlgorithm, hashLength) = hashInfoForAlgorithm(algorithm)
    let hashPointer = UnsafeMutablePointer<UInt8>.alloc(hashLength)
    defer { hashPointer.dealloc(hashLength) }
    CCHmac(hashAlgorithm, secret.bytes, secret.length, &bigCounter, sizeof(UInt64), hashPointer)

    // Use the last 4 bits of the hash as an offset (0 <= offset <= 15)
    let ptr = UnsafePointer<UInt8>(hashPointer)
    let offset = ptr[hashLength-1] & 0x0f

    // Take 4 bytes from the hash, starting at the given byte offset
    let truncatedHashPtr = ptr + Int(offset)
    var truncatedHash = UnsafePointer<UInt32>(truncatedHashPtr).memory

    // Ensure the four bytes taken from the hash match the current endian format
    truncatedHash = UInt32(bigEndian: truncatedHash)
    // Discard the most significant bit
    truncatedHash &= 0x7fffffff
    // Constrain to the right number of digits
    truncatedHash = truncatedHash % UInt32(pow(10, Float(digits)))

    // Pad the string representation with zeros, if necessary
    return String(truncatedHash).paddedWithCharacter("0", toLength: digits)
}

private extension String {
    func paddedWithCharacter(character: Character, toLength length: Int) -> String {
        let paddingCount = length - characters.count
        guard paddingCount > 0 else { return self }

        let padding = String(count: paddingCount, repeatedValue: character)
        return padding + self
    }
}
