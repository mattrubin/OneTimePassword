//
//  GeneratorFunctions.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 8/25/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import Foundation

internal func validateGenerator(factor factor: Generator.Factor, secret: NSData, algorithm: Generator.Algorithm, digits: Int) -> Bool {
    let validDigits: (Int) -> Bool = { (6 <= $0) && ($0 <= 8) }
    let validPeriod: (NSTimeInterval) -> Bool = { (0 < $0) && ($0 <= 300) }

    switch factor {
    case .Counter:
        return validDigits(digits)
    case .Timer(let period):
        return validDigits(digits) && validPeriod(period)
    }
}

public func counterForGeneratorWithFactor(factor: Generator.Factor, atTimeIntervalSince1970 timeInterval: NSTimeInterval) -> UInt64 {
    switch factor {
    case .Counter(let counter):
        return counter
    case .Timer(let period):
        return UInt64(timeInterval / period)
    }
}

public func generatePassword(algorithm algorithm: Generator.Algorithm, digits: Int, secret: NSData, counter: UInt64) -> String? {
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
    guard let hash = NSMutableData(length: hashLength)
        else { return nil }
    CCHmac(hashAlgorithm, secret.bytes, secret.length, &bigCounter, 8, hash.mutableBytes)

    // Use the last 4 bits of the hash as an offset (0 <= offset <= 15)
    let ptr = UnsafePointer<UInt8>(hash.bytes)
    let offset = ptr[hash.length-1] & 0x0f

    // Take 4 bytes from the hash, starting at the given byte offset
    let truncatedHashPtr = ptr + Int(offset)
    var truncatedHash = UnsafePointer<UInt32>(truncatedHashPtr).memory

    // Ensure the four bytes taken from the hash match the current endian format
    truncatedHash = UInt32(bigEndian: truncatedHash)
    // Discard the most significant bit
    truncatedHash &= 0x7fffffff
    // Constrain to the right number of digits
    truncatedHash = truncatedHash % UInt32(pow(10, Float(digits)))

    var string = String(truncatedHash)
    // Pad the string representation with zeros, if necessary
    while string.characters.count < digits {
        string = "0" + string
    }
    return string
}
