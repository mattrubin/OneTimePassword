//
//  OTPToken+Defaults.m
//  OneTimePassword
//
//  Created by Matt Rubin on 7/9/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

#import "OTPToken+Defaults.h"

@implementation OTPToken (Defaults)

+ (NSTimeInterval)defaultPeriod
{
    return 30;
}

+ (uint64_t)defaultInitialCounter
{
    return 1;
}

@end
