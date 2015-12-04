//
//  OTPTypeStrings.h
//  OneTimePassword
//
//  Created by Matt Rubin on 7/9/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

@import Foundation;
#import "OneTimePasswordLegacyTests-Swift.h"


#pragma mark - OTPTokenType

@interface NSString (OTPTokenType)
+ (instancetype)stringForTokenType:(OTPTokenType)tokenType;
@end


#pragma mark - OTPAlgorithm

extern NSString *const kOTPAlgorithmSHA1;
extern NSString *const kOTPAlgorithmSHA256;
extern NSString *const kOTPAlgorithmSHA512;

@interface NSString (OTPAlgorithm)
+ (instancetype)stringForAlgorithm:(OTPAlgorithm)algorithm;
@end
