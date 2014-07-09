//
//  OTPToken+Generation.m
//  Authenticator
//
//  Copyright (c) 2013 Matt Rubin
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "OTPToken+Generation.h"
#import "OTPToken+Persistence.h"
#import <CommonCrypto/CommonHMAC.h>
#import <OneTimePassword/OneTimePassword-Swift.h>


static NSUInteger kPinModTable[] = {
    0,
    10,
    100,
    1000,
    10000,
    100000,
    1000000,
    10000000,
    100000000,
};

CCHmacAlgorithm hashAlgorithmForAlgorithm(OTPAlgorithm algorithm)
{
    switch (algorithm) {
        case OTPAlgorithmSHA1:
            return kCCHmacAlgSHA1;
        case OTPAlgorithmSHA256:
            return kCCHmacAlgSHA256;
        case OTPAlgorithmSHA512:
            return kCCHmacAlgSHA512;
    }
}

NSUInteger digestLengthForAlgorithm(CCHmacAlgorithm algorithm)
{
    switch (algorithm) {
        case kCCHmacAlgSHA1:
            return CC_SHA1_DIGEST_LENGTH;
        case kCCHmacAlgSHA256:
            return CC_SHA256_DIGEST_LENGTH;
        case kCCHmacAlgSHA512:
            return CC_SHA512_DIGEST_LENGTH;
        default:
            return 0;
    }
}

NSString *passwordForToken(NSData *secret, CCHmacAlgorithm algorithm, NSUInteger digits, uint64_t counter)
{
    // Ensure the counter value is big-endian
    counter = NSSwapHostLongLongToBig(counter);

    // Generate an HMAC value from the key and counter
    NSMutableData *hash = [NSMutableData dataWithLength:digestLengthForAlgorithm(algorithm)];
    CCHmac(algorithm, secret.bytes, secret.length, &counter, sizeof(counter), hash.mutableBytes);

    // Use the last 4 bits of the hash as an offset (0 <= offset <= 15)
    const char *ptr = hash.bytes;
    unsigned char offset = ptr[hash.length-1] & 0x0f;

    // Take 4 bytes from the hash, starting at the given offset
    const void *truncatedHashPtr = &ptr[offset];
    unsigned int truncatedHash = *(unsigned int *)truncatedHashPtr;

    // Ensure the four bytes taken from the hash match the current endian format
    truncatedHash = NSSwapBigIntToHost(truncatedHash);
    // Discard the most significant bit
    truncatedHash &= 0x7fffffff;

    unsigned long pinValue = truncatedHash % kPinModTable[digits];

    return [NSString stringWithFormat:@"%0*ld", (int)digits, pinValue];
}
