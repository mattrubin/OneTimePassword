//
//  NSData+Secret.m
//  OneTimePassword
//
//  Created by Matt Rubin on 7/23/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

#import "NSData+Secret.h"
#import <Base32/MF_Base32Additions.h>


@implementation NSData (Secret)

+ (NSData *)secretWithString:(NSString *)string
{
    return [NSData dataWithBase32String:string];
}

@end
