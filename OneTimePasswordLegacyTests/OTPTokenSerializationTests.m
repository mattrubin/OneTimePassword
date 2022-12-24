//
//  OTPTokenSerializationTests.m
//  OneTimePassword
//
//  Copyright (c) 2013-2017 Matt Rubin and the OneTimePassword authors
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

@import XCTest;
@import Base32;
#import "OneTimePasswordLegacyTests-Swift.h"
#import "OTPTypeStrings.h"


static NSString * const kOTPScheme = @"otpauth";
static NSString * const kOTPTokenTypeCounterHost = @"hotp";
static NSString * const kOTPTokenTypeTimerHost   = @"totp";
static NSString * const kRandomKey = @"RANDOM";

static NSArray *typeNumbers;
static NSArray *names;
static NSArray *issuers;
static NSArray *secretStrings;
static NSArray *algorithmNumbers;
static NSArray *digitNumbers;
static NSArray *periodNumbers;
static NSArray *counterNumbers;

static const unsigned char kValidSecret[] = { 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
                                              0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f };


@interface OTPTokenSerializationTests : XCTestCase

@end


@implementation OTPTokenSerializationTests

+ (void)setUp
{
    [super setUp];

    typeNumbers = @[@(OTPTokenTypeCounter), @(OTPTokenTypeTimer)];
    names = @[@"", @"Login", @"user123@website.com", @"Léon", @":/?#[]@!$&'()*+,;=%\""];
    issuers = @[@"", @"Big Cörpøráçìôn", @":/?#[]@!$&'()*+,;=%\""];
    secretStrings = @[@"12345678901234567890", @"12345678901234567890123456789012",
                      @"1234567890123456789012345678901234567890123456789012345678901234", @""];
    algorithmNumbers = @[@(OTPAlgorithmSHA1), @(OTPAlgorithmSHA256), @(OTPAlgorithmSHA512)];
    digitNumbers = @[@0, @6, @8];
    periodNumbers = @[@0, @1, @30, kRandomKey];
    counterNumbers = @[@0, @1, @99999, kRandomKey];
}

#pragma mark - Brute Force Tests

- (void)testDeserialization
{
    for (NSNumber *typeNumber in typeNumbers) {
        for (NSString *name in names) {
            for (NSString *issuer in issuers) {
                for (NSString *secretString in secretStrings) {
                    for (NSNumber *algorithmNumber in algorithmNumbers) {
                        for (NSNumber *digitNumber in digitNumbers) {
                            for (NSNumber *periodNumber in periodNumbers) {
                                for (NSNumber *counterNumber in counterNumbers) {
                                    // Construct the URL
                                    NSURLComponents *urlComponents = [NSURLComponents new];
                                    urlComponents.scheme = kOTPScheme;
                                    urlComponents.host = [NSString stringForTokenType:[typeNumber unsignedCharValue]];
                                    urlComponents.path = [@"/" stringByAppendingString:name];

                                    NSMutableArray *queryItems = [NSMutableArray array];
                                    NSString *algorithmValue = [NSString stringForAlgorithm:[algorithmNumber unsignedIntValue]];
                                    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"algorithm"
                                                                                      value:algorithmValue]];
                                    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"digits"
                                                                                      value:[digitNumber stringValue]]];
                                    NSString *secretValue = [[[secretString dataUsingEncoding:NSASCIIStringEncoding] base32String] stringByReplacingOccurrencesOfString:@"=" withString:@""];
                                    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"secret"
                                                                                      value:secretValue]];
                                    NSNumber *periodValue = [periodNumber isEqual:kRandomKey] ? @(arc4random()%299 + 1) : periodNumber;
                                    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"period"
                                                                                      value:[periodValue stringValue]]];
                                    NSNumber *counterValue = [counterNumber isEqual:kRandomKey] ? @(arc4random() + ((uint64_t)arc4random() << 32)) : counterNumber;
                                    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"counter"
                                                                                      value:[counterValue stringValue]]];
                                    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"issuer"
                                                                                      value:issuer]];
                                    urlComponents.queryItems = queryItems;

                                    // Create the token
                                    OTPToken *token = [OTPToken tokenWithURL:[urlComponents URL]];

                                    // Note: [OTPToken tokenWithURL:] will return nil if the token described by the URL is invalid.
                                    if (token) {
                                        XCTAssertEqual(token.type, [typeNumber unsignedCharValue], @"Incorrect token type");
                                        XCTAssertEqualObjects(token.name, name, @"Incorrect token name");
                                        XCTAssertEqualObjects(token.issuer, issuer, @"Incorrect token issuer");
                                        XCTAssertEqualObjects(token.secret, [secretString dataUsingEncoding:NSASCIIStringEncoding], @"Incorrect token secret");
                                        XCTAssertEqual(token.algorithm, [algorithmNumber unsignedIntValue], @"Incorrect token algorithm");
                                        XCTAssertEqual(token.digits, [digitNumber unsignedIntegerValue], @"Incorrect token digits");
                                        if (token.type == OTPTokenTypeTimer)
                                            XCTAssertTrue(ABS(token.period - [periodValue doubleValue]) < DBL_EPSILON, @"Incorrect token period");
                                        if (token.type == OTPTokenTypeCounter)
                                            XCTAssertEqual(token.counter, [counterValue unsignedLongLongValue], @"Incorrect token counter");
                                    } else {
                                        // If nil was returned from [OTPToken tokenWithURL:], create the same token manually and ensure it's invalid
                                        OTPToken *invalidToken = [OTPToken new];
                                        invalidToken.type = [typeNumber unsignedCharValue];
                                        invalidToken.name = name;
                                        invalidToken.issuer = issuer;
                                        invalidToken.secret = [secretString dataUsingEncoding:NSASCIIStringEncoding];
                                        invalidToken.algorithm = [algorithmNumber unsignedIntValue];
                                        invalidToken.digits = [digitNumber unsignedIntegerValue];
                                        invalidToken.period = [periodValue doubleValue];
                                        invalidToken.counter = [counterValue unsignedLongLongValue];

                                        XCTAssertFalse([invalidToken validate], @"The token should be invalid");
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

- (void)testTokenWithURLAndSecret
{
    for (NSNumber *typeNumber in typeNumbers) {
        for (NSString *name in names) {
            for (NSString *issuer in issuers) {
                for (NSString *secretString in secretStrings) {
                    for (NSNumber *algorithmNumber in algorithmNumbers) {
                        for (NSNumber *digitNumber in digitNumbers) {
                            for (NSNumber *periodNumber in periodNumbers) {
                                for (NSNumber *counterNumber in counterNumbers) {
                                    // Construct the URL
                                    NSURLComponents *urlComponents = [NSURLComponents new];
                                    urlComponents.scheme = kOTPScheme;
                                    urlComponents.host = [NSString stringForTokenType:[typeNumber unsignedCharValue]];
                                    urlComponents.path = [@"/" stringByAppendingString:name];

                                    NSMutableArray *queryItems = [NSMutableArray array];
                                    NSString *algorithmValue = [NSString stringForAlgorithm:[algorithmNumber unsignedIntValue]];
                                    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"algorithm"
                                                                                      value:algorithmValue]];
                                    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"digits"
                                                                                      value:[digitNumber stringValue]]];
                                    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"secret"
                                                                                      value:@"A"]];
                                    NSNumber *periodValue = [periodNumber isEqual:kRandomKey] ? @(arc4random()%299 + 1) : periodNumber;
                                    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"period"
                                                                                      value:[periodValue stringValue]]];
                                    NSNumber *counterValue = [counterNumber isEqual:kRandomKey] ? @(arc4random() + ((uint64_t)arc4random() << 32)) : counterNumber;
                                    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"counter"
                                                                                      value:[counterValue stringValue]]];
                                    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"issuer"
                                                                                      value:issuer]];
                                    urlComponents.queryItems = queryItems;

                                    // Create the token
                                    NSData *secret = [secretString dataUsingEncoding:NSASCIIStringEncoding];
                                    OTPToken *token = [OTPToken tokenWithURL:[urlComponents URL] secret:secret];

                                    // Note: [OTPToken tokenWithURL:] will return nil if the token described by the URL is invalid.
                                    if (token) {
                                        XCTAssertEqual(token.type, [typeNumber unsignedCharValue], @"Incorrect token type");
                                        XCTAssertEqualObjects(token.name, name, @"Incorrect token name");
                                        XCTAssertEqualObjects(token.issuer, issuer, @"Incorrect token issuer");
                                        XCTAssertEqualObjects(token.secret, secret, @"Incorrect token secret");
                                        XCTAssertEqual(token.algorithm, [algorithmNumber unsignedIntValue], @"Incorrect token algorithm");
                                        XCTAssertEqual(token.digits, [digitNumber unsignedIntegerValue], @"Incorrect token digits");
                                        if (token.type == OTPTokenTypeTimer)
                                            XCTAssertTrue(ABS(token.period - [periodValue doubleValue]) < DBL_EPSILON, @"Incorrect token period");
                                        if (token.type == OTPTokenTypeCounter)
                                            XCTAssertEqual(token.counter, [counterValue unsignedLongLongValue], @"Incorrect token counter");
                                    } else {
                                        // If nil was returned from [OTPToken tokenWithURL:], create the same token manually and ensure it's invalid
                                        OTPToken *invalidToken = [OTPToken new];
                                        invalidToken.type = [typeNumber unsignedCharValue];
                                        invalidToken.name = name;
                                        invalidToken.issuer = issuer;
                                        invalidToken.secret = secret;
                                        invalidToken.algorithm = [algorithmNumber unsignedIntValue];
                                        invalidToken.digits = [digitNumber unsignedIntegerValue];
                                        invalidToken.period = [periodValue doubleValue];
                                        invalidToken.counter = [counterValue unsignedLongLongValue];

                                        XCTAssertFalse([invalidToken validate], @"The token should be invalid");
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

- (void)testSerialization
{
    for (NSNumber *typeNumber in typeNumbers) {
        for (NSString *name in names) {
            for (NSString *issuer in issuers) {
                for (NSString *secretString in secretStrings) {
                    for (NSNumber *algorithmNumber in algorithmNumbers) {
                        for (NSNumber *digitNumber in digitNumbers) {
                            for (NSNumber *periodNumber in periodNumbers) {
                                for (NSNumber *counterNumber in counterNumbers) {

                                    NSTimeInterval period;
                                    if ([periodNumber isEqual:kRandomKey]) {
                                        period = (arc4random()%299 + 1);
                                    } else {
                                        period = [periodNumber doubleValue];
                                    }

                                    uint64_t counter;
                                    if ([counterNumber isEqual:kRandomKey]) {
                                        counter = arc4random() + ((uint64_t)arc4random() << 32);
                                    } else {
                                        counter = [counterNumber unsignedLongLongValue];
                                    }

                                    // Create the token
                                    OTPToken *token = [OTPToken new];
                                    token.type = [typeNumber unsignedCharValue];
                                    token.name = name;
                                    token.secret = [secretString dataUsingEncoding:NSASCIIStringEncoding];
                                    token.algorithm = [algorithmNumber unsignedIntValue];
                                    token.digits = [digitNumber unsignedIntegerValue];
                                    token.period = period;
                                    token.counter = counter;
                                    token.issuer = issuer;

                                    // Serialize
                                    NSURL *url = token.url;

                                    // An invalid token should not (cannot) produce a URL
                                    if (![token validate]) {
                                        XCTAssertNil(url);
                                        continue;
                                    }

                                    // Test scheme
                                    XCTAssertEqualObjects(url.scheme, kOTPScheme,
                                                          @"The url scheme should be \"%@\"", kOTPScheme);
                                    // Test type
                                    NSString *expectedHost = [typeNumber unsignedCharValue] == OTPTokenTypeCounter ? kOTPTokenTypeCounterHost : kOTPTokenTypeTimerHost;
                                    XCTAssertEqualObjects(url.host, expectedHost,
                                                          @"The url host should be \"%@\"", expectedHost);
                                    // Test name
                                    if (name) {
                                        XCTAssertEqualObjects([url.path substringFromIndex:1] , name,
                                                              @"The url path should be \"%@\"", name);
                                    } else {
                                        XCTAssertEqualObjects(url.path, @"", @"The url path should be empty");
                                    }

                                    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url
                                                                                resolvingAgainstBaseURL:NO];
                                    NSArray<NSURLQueryItem *> *queryItems = urlComponents.queryItems;
                                    NSMutableDictionary *queryArguments = [NSMutableDictionary dictionaryWithCapacity:queryItems.count];
                                    for (NSURLQueryItem *queryItem in queryItems) {
                                        XCTAssertNil([queryArguments objectForKey:queryItem.name]);
                                        [queryArguments setObject:queryItem.value forKey:queryItem.name];
                                    }

                                    // Test algorithm
                                    NSString *expectedAlgorithmString = [NSString stringForAlgorithm:[algorithmNumber unsignedIntValue]];
                                    XCTAssertEqualObjects(queryArguments[@"algorithm"], expectedAlgorithmString,
                                                          @"The algorithm value should be \"%@\"", expectedAlgorithmString);
                                    // Test digits
                                    NSString *expectedDigitsString = [digitNumber stringValue];
                                    XCTAssertEqualObjects(queryArguments[@"digits"], expectedDigitsString,
                                                          @"The digits value should be \"%@\"", expectedDigitsString);
                                    // Test secret
                                    XCTAssertNil(queryArguments[@"secret"], @"The url query string should not contain the secret");

                                    // Test period
                                    if ([typeNumber unsignedCharValue] == OTPTokenTypeTimer) {
                                        NSString *expectedPeriodString = [@(period) stringValue];
                                        XCTAssertEqualObjects(queryArguments[@"period"], expectedPeriodString,
                                                              @"The period value should be \"%@\"", expectedPeriodString);
                                    } else {
                                        XCTAssertNil(queryArguments[@"period"], @"The url query string should not contain the period");
                                    }
                                    // Test counter
                                    if ([typeNumber unsignedCharValue] == OTPTokenTypeCounter) {
                                        NSString *expectedCounterString = [@(counter) stringValue];
                                        XCTAssertEqualObjects(queryArguments[@"counter"], expectedCounterString,
                                                              @"The counter value should be \"%@\"", expectedCounterString);
                                    } else {
                                        XCTAssertNil(queryArguments[@"counter"], @"The url query string should not contain the counter");
                                    }

                                    // Test issuer
                                    XCTAssertEqualObjects(queryArguments[@"issuer"], issuer,
                                                          @"The issuer value should be \"%@\"", issuer);

                                    XCTAssertEqual(queryArguments.count, (NSUInteger)(issuer ? 4 : 3), @"There shouldn't be any unexpected query arguments");

                                    // Check url again
                                    NSURL *checkURL = token.url;
                                    XCTAssertEqualObjects(url, checkURL, @"Repeated calls to -url should return the same result!");
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@end
