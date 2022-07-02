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

                                    XCTAssertEqual(queryArguments.count, (NSUInteger)(issuer ? 5 : 4), @"There shouldn't be any unexpected query arguments");

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


#pragma mark - Test with specific URLs
// From Google Authenticator for iOS
// https://code.google.com/p/google-authenticator/source/browse/mobile/ios/Classes/OTPAuthURLTest.m

#pragma mark Deserialization

- (void)testTokenWithTOTPURL
{
    NSData *secret = [NSData dataWithBytes:kValidSecret length:sizeof(kValidSecret)];
    OTPToken *token = [OTPToken tokenWithURL:[NSURL URLWithString:@"otpauth://totp/L%C3%A9on?algorithm=SHA256&digits=8&period=45&secret=AAAQEAYEAUDAOCAJBIFQYDIOB4"]];

    XCTAssertEqualObjects(token.name, @"Léon");
    XCTAssertEqualObjects(token.secret, secret);
    XCTAssertEqual(token.type, OTPTokenTypeTimer);
    XCTAssertEqual(token.algorithm, OTPAlgorithmSHA256);
    XCTAssertTrue(ABS(token.period - 45.0) < DBL_EPSILON);
    XCTAssertEqual(token.digits, 8U);
}

- (void)testTokenWithHOTPURL
{
    NSData *secret = [NSData dataWithBytes:kValidSecret length:sizeof(kValidSecret)];
    OTPToken *token = [OTPToken tokenWithURL:[NSURL URLWithString:@"otpauth://hotp/L%C3%A9on?algorithm=SHA256&digits=8&counter=18446744073709551615&secret=AAAQEAYEAUDAOCAJBIFQYDIOB4"]];

    XCTAssertEqualObjects(token.name, @"Léon");
    XCTAssertEqualObjects(token.secret, secret);
    XCTAssertEqual(token.type, OTPTokenTypeCounter);
    XCTAssertEqual(token.algorithm, OTPAlgorithmSHA256);
    XCTAssertEqual(token.counter, 18446744073709551615ULL);
    XCTAssertEqual(token.digits, 8U);
}

- (void)testTokenWithInvalidURLs
{
    NSArray *badURLs = @[@"http://foo", // invalid scheme
                         @"otpauth://foo", // invalid type
                         @"otpauth:///bar?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4", // missing type
                         @"otpauth://totp/bar", // missing secret
                         @"otpauth://totp/bar?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4&period=0", // invalid period
                         @"otpauth://totp/bar?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4&period=x", // non-numeric period
                         @"otpauth://totp/bar?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4&period=30&period=60", // multiple period
                         @"otpauth://totp/bar?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4&algorithm=MD5", // invalid algorithm
                         @"otpauth://totp/bar?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4&digits=2", // invalid digits
                         @"otpauth://totp/bar?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4&digits=x", // non-numeric digits
                         @"otpauth://hotp/bar?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4&counter=1.5", // invalid counter
                         @"otpauth://hotp/bar?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4&counter=x", // non-numeric counter
                         ];

    for (NSString *badURL in badURLs) {
        OTPToken *token = [OTPToken tokenWithURL:[NSURL URLWithString:badURL]];
        XCTAssertNil(token, @"Invalid url (%@) generated %@", badURL, token);
    }
}

- (void)testTokenWithIssuer
{
    OTPToken *simpleToken = [OTPToken tokenWithURL:[NSURL URLWithString:@"otpauth://totp/name?secret=A&issuer=issuer"]];
    XCTAssertNotNil(simpleToken);
    XCTAssertEqualObjects(simpleToken.name, @"name");
    XCTAssertEqualObjects(simpleToken.issuer, @"issuer");

    // TODO: test this more thoroughly, including the override case with "otpauth://totp/_issuer:name?secret=A&isser=issuer"

    NSArray *urlStrings = @[@"otpauth://totp/issu%C3%A9r%20!:name?secret=A",
                            @"otpauth://totp/issu%C3%A9r%20!:%20name?secret=A",
                            @"otpauth://totp/issu%C3%A9r%20!:%20%20%20name?secret=A",
                            @"otpauth://totp/issu%C3%A9r%20!%3Aname?secret=A",
                            @"otpauth://totp/issu%C3%A9r%20!%3A%20name?secret=A",
                            @"otpauth://totp/issu%C3%A9r%20!%3A%20%20%20name?secret=A",
                            ];
    for (NSString *urlString in urlStrings) {
        // If there is no issuer argument, extract the issuer from the name
        OTPToken *token = [OTPToken tokenWithURL:[NSURL URLWithString:urlString]];

        XCTAssertNotNil(token, @"<%@> did not create a valid token.", urlString);
        XCTAssertEqualObjects(token.name, @"name");
        XCTAssertEqualObjects(token.issuer, @"issuér !");

        // If there is an issuer argument which matches the one in the name, trim the name
        OTPToken *token2 = [OTPToken tokenWithURL:[NSURL URLWithString:[urlString stringByAppendingString:@"&issuer=issu%C3%A9r%20!"]]];

        XCTAssertNotNil(token2, @"<%@> did not create a valid token.", urlString);
        XCTAssertEqualObjects(token2.name, @"name");
        XCTAssertEqualObjects(token2.issuer, @"issuér !");

        // If there is an issuer argument different from the name prefix,
        // trust the argument and leave the name as it is
        OTPToken *token3 = [OTPToken tokenWithURL:[NSURL URLWithString:[urlString stringByAppendingString:@"&issuer=test"]]];

        XCTAssertNotNil(token3, @"<%@> did not create a valid token.", urlString);
        XCTAssertNotEqualObjects(token3.name, @"name");
        XCTAssertTrue([token3.name rangeOfString:@"issuér !"].location == 0, @"The name should begin with \"issuér !\"");
        XCTAssertTrue([token3.name rangeOfString:@"name"].location == token3.name.length-4, @"The name should end with \"name\"");
        XCTAssertEqualObjects(token3.issuer, @"test");
    }
}


#pragma mark Serialization

- (void)testTOTPURL
{
    OTPToken *token = [OTPToken tokenWithURL:[NSURL URLWithString:@"otpauth://totp/L%C3%A9on?algorithm=SHA256&digits=8&period=45&secret=AAAQEAYEAUDAOCAJBIFQYDIOB4"]];
    NSURL *url = token.url;

    XCTAssertEqualObjects(url.scheme, @"otpauth");
    XCTAssertEqualObjects(url.host, @"totp");
    XCTAssertEqualObjects([url.path substringFromIndex:1], @"Léon");

    NSArray *expectedQueryItems = @[[NSURLQueryItem queryItemWithName:@"algorithm" value:@"SHA256"],
                                    [NSURLQueryItem queryItemWithName:@"digits" value:@"8"],
                                    [NSURLQueryItem queryItemWithName:@"representation" value:@"numeric"],
                                    [NSURLQueryItem queryItemWithName:@"issuer" value:@""],
                                    [NSURLQueryItem queryItemWithName:@"period" value:@"45"]];
    NSArray *queryItems = [NSURLComponents componentsWithURL:url
                                     resolvingAgainstBaseURL:NO].queryItems;
    XCTAssertEqualObjects(queryItems, expectedQueryItems);
}

- (void)testHOTPURL
{
    OTPToken *token = [OTPToken tokenWithURL:[NSURL URLWithString:@"otpauth://hotp/L%C3%A9on?algorithm=SHA256&digits=8&counter=18446744073709551615&secret=AAAQEAYEAUDAOCAJBIFQYDIOB4"]];
    NSURL *url = token.url;

    XCTAssertEqualObjects(url.scheme, @"otpauth");
    XCTAssertEqualObjects(url.host, @"hotp");
    XCTAssertEqualObjects([url.path substringFromIndex:1], @"Léon");

    NSArray *expectedQueryItems = @[[NSURLQueryItem queryItemWithName:@"algorithm" value:@"SHA256"],
                                    [NSURLQueryItem queryItemWithName:@"digits" value:@"8"],
                                    [NSURLQueryItem queryItemWithName:@"representation" value:@"numeric"],
                                    [NSURLQueryItem queryItemWithName:@"issuer" value:@""],
                                    [NSURLQueryItem queryItemWithName:@"counter" value:@"18446744073709551615"]];
    NSArray *queryItems = [NSURLComponents componentsWithURL:url
                                     resolvingAgainstBaseURL:NO].queryItems;
    XCTAssertEqualObjects(queryItems, expectedQueryItems);
}

@end
