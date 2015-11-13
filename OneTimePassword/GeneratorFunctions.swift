//
//  GeneratorFunctions.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 8/25/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import Foundation
import CommonCrypto

internal func generatePassword(algorithm algorithm: Generator.Algorithm, digits: Int, secret: NSData, counter: UInt64) throws -> String {
    guard Generator.validateDigits(digits) else {
        throw Generator.Error.InvalidDigits
    }

    // Ensure the counter value is big-endian
    var bigCounter = counter.bigEndian

    // Generate an HMAC value from the key and counter
    let (hashAlgorithm, hashLength) = Generator.hashInfoForAlgorithm(algorithm)
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
