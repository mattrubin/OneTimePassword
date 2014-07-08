//
//  OTPToken+Serialization.m
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

#import "OTPToken+Serialization.h"
#import <OneTimePassword/OneTimePassword-Swift.h>


@interface OTPToken ()
@property (nonatomic, strong) Token *core;
@end


static NSString *const kOTPAuthScheme = @"otpauth";


@implementation OTPToken (Serialization)

+ (instancetype)tokenWithURL:(NSURL *)url
{
    return [self tokenWithURL:url secret:nil];
}

+ (instancetype)tokenWithURL:(NSURL *)url secret:(NSData *)secret
{
    OTPToken *token = nil;

    if ([url.scheme isEqualToString:kOTPAuthScheme]) {
        // Modern otpauth:// URL
        token = [self tokenWithOTPAuthURL:url secret:secret];
    }

    return [token validate] ? token : nil;
}

+ (instancetype)tokenWithOTPAuthURL:(NSURL *)url secret:(NSData *)secret
{
    return [[OTPToken alloc] initWithCore:[[Token alloc] initWithURL:url secret:secret]];
}

- (NSURL *)url { return self.core.url; }

@end


@implementation NSURL (QueryDictionary)

- (NSDictionary *)queryDictionary
{
    NSArray *queryItems = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO].queryItems;
    NSMutableDictionary *queryDictionary = [NSMutableDictionary dictionaryWithCapacity:queryItems.count];
    for (NSURLQueryItem *item in queryItems) {
        queryDictionary[item.name] = item.value;
    }
    return queryDictionary;
}

@end


@implementation NSDictionary (QueryItems)

- (NSArray *)queryItemsArray
{
    NSMutableArray *queryItems = [NSMutableArray arrayWithCapacity:self.count];
    for (NSString *key in self) {
        id value = self[key];
        if ([value isKindOfClass:[NSNumber class]]) {
            value = ((NSNumber *)value).stringValue;
        } else if (![value isKindOfClass:[NSString class]]) {
            NSAssert(NO, @":(");
        }
        [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:value]];
    }
    return queryItems;
}

@end
