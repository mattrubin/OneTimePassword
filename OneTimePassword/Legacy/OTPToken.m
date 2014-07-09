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


@interface OTPLegacyToken ()
@property (nonatomic, strong) OTPToken *core;
@end

@implementation OTPLegacyToken

- (instancetype)initWithCore:(OTPToken *)core
{
    if (!core) return nil;

    self = [super init];
    if (self) {
        self.core = core;
    }
    return self;
}

- (NSString *)description { return self.core.description; }

- (NSString *)name { return self.core.name; }
- (NSString *)issuer { return self.core.issuer; }
- (OTPTokenType)type { return self.core.type; }
- (NSData *)secret { return self.core.secret; }
- (OTPAlgorithm)algorithm { return self.core.algorithm; }
- (NSUInteger)digits { return self.core.digits; }
- (NSTimeInterval)period { return self.core.period; }
- (uint64_t)counter { return self.core.counter; }


#pragma mark - Serialization

+ (instancetype)tokenWithURL:(NSURL *)url
{
    return [[self alloc] initWithCore:[OTPToken tokenWithURL:url]];
}

+ (instancetype)tokenWithURL:(NSURL *)url secret:(NSData *)secret
{
    return [[self alloc] initWithCore:[OTPToken tokenWithURL:url secret:secret]];
}

- (NSURL *)url { return self.core.url; }

@end
