//
//  NSData+Secret.h
//  OneTimePassword
//
//  Created by Matt Rubin on 7/23/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSData (Secret)

+ (NSData *)secretWithString:(NSString *)string;

@end
