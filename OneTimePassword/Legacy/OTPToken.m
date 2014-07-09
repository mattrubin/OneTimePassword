//
//  OTPToken.m
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

#import "OTPToken.h"
#import <OneTimePassword/OneTimePassword-Swift.h>

@implementation OTPToken

- (instancetype)initWithType:(OTPTokenType)type secret:(NSData *)secret name:(NSString *)name issuer:(NSString *)issuer algorithm:(OTPAlgorithm)algorithm digits:(NSUInteger)digits period:(NSTimeInterval)period
{
    NSAssert(secret != nil, @"Token secret must be non-nil");
    NSAssert(name != nil, @"Token name must be non-nil");
    NSAssert(issuer != nil, @"Token issuer must be non-nil");
    return [self initWithCore:[[OTPTokenBridge alloc] initWithType:type secret:secret name:name issuer:issuer algorithm:algorithm digits:digits period:period]];
}

- (instancetype)initWithCore:(OTPTokenBridge *)core
{
    if (!core) return nil;

    self = [super init];
    if (self) {
        self.core = core;
    }
    return self;
}

- (id)init
{
    NSAssert(NO, @"Use -initWithType:secret:name:issuer:algorithm:digits:period:");
    return nil;
}


- (NSString *)description { return self.core.description; }
- (BOOL)validate { return self.core.isValid; }

- (NSString *)name { return self.core.name; }
- (NSString *)issuer { return self.core.issuer; }
- (OTPTokenType)type { return self.core.type; }
- (NSData *)secret { return self.core.secret; }
- (OTPAlgorithm)algorithm { return self.core.algorithm; }
- (NSUInteger)digits { return self.core.digits; }
- (NSTimeInterval)period { return self.core.period; }

- (uint64_t)counter { return self.core.counter; }
- (void)setCounter:(uint64_t)counter { self.core.counter = counter; }


#pragma mark - Serialization

+ (instancetype)tokenWithURL:(NSURL *)url
{
    return [[OTPToken alloc] initWithCore:[OTPTokenBridge tokenWithURL:url]];
}

+ (instancetype)tokenWithURL:(NSURL *)url secret:(NSData *)secret
{
    return [[OTPToken alloc] initWithCore:[OTPTokenBridge tokenWithURL:url secret:secret]];
}

- (NSURL *)url { return self.core.url; }

@end
