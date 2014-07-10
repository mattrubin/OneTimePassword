//
//  OTPTypeStrings.m
//  OneTimePassword
//
//  Created by Matt Rubin on 7/9/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

#import "OTPTypeStrings.h"


#pragma mark - OTPTokenType

NSString *const kOTPTokenTypeCounter = @"hotp";
NSString *const kOTPTokenTypeTimer = @"totp";

@implementation NSString (OTPTokenType)

+ (instancetype)stringForTokenType:(OTPTokenType)tokenType
{
    switch (tokenType) {
        case OTPTokenTypeCounter:
            return kOTPTokenTypeCounter;
        case OTPTokenTypeTimer:
            return kOTPTokenTypeTimer;
    }
}

@end


#pragma mark - OTPAlgorithm

OTPAlgorithm OTPAlgorithmUnknown = UINT8_MAX;

NSString *const kOTPAlgorithmSHA1 = @"SHA1";
NSString *const kOTPAlgorithmSHA256 = @"SHA256";
NSString *const kOTPAlgorithmSHA512 = @"SHA512";

@implementation NSString (OTPAlgorithm)

+ (instancetype)stringForAlgorithm:(OTPAlgorithm)algorithm
{
    switch (algorithm) {
        case OTPAlgorithmSHA1:
            return kOTPAlgorithmSHA1;
        case OTPAlgorithmSHA256:
            return kOTPAlgorithmSHA256;
        case OTPAlgorithmSHA512:
            return kOTPAlgorithmSHA512;
    }
}

- (OTPAlgorithm)algorithmValue
{
    if ([self isEqualToString:kOTPAlgorithmSHA1]) {
        return OTPAlgorithmSHA1;
    } else if ([self isEqualToString:kOTPAlgorithmSHA256]) {
        return OTPAlgorithmSHA256;
    } else if ([self isEqualToString:kOTPAlgorithmSHA512]) {
        return OTPAlgorithmSHA512;
    }

    return OTPAlgorithmUnknown;
}

@end
