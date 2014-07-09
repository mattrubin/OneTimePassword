//
//  OTPToken+Defaults.h
//  OneTimePassword
//
//  Created by Matt Rubin on 7/9/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

@import OneTimePassword;

@interface OTPToken (Defaults)

+ (NSTimeInterval)defaultPeriod;
+ (uint64_t)defaultInitialCounter;

@end
