//
//  OTPTokenGenerationTests.m
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

@import XCTest;
#import <OneTimePassword/OTPToken+Generation.h>


@interface OTPToken ()
- (NSString *)generatePasswordForCounter:(uint64_t)counter;
@end


@interface OTPTokenGenerationTests : XCTestCase
@end


@implementation OTPTokenGenerationTests

// The values in this test are found in Appendix D of the HOTP RFC
// https://tools.ietf.org/html/rfc4226#appendix-D
- (void)testHOTPRFCValues
{
    NSData *secret = [@"12345678901234567890" dataUsingEncoding:NSASCIIStringEncoding];
    OTPToken *token = [[OTPToken alloc] initWithType:OTPTokenTypeCounter
                                              secret:secret
                                                name:@""
                                              issuer:@""
                                           algorithm:OTPAlgorithmSHA1
                                              digits:6
                                              period:[OTPToken defaultPeriod]];

    XCTAssertEqualObjects(@"755224", [token generatePasswordForCounter:0], @"The 0th OTP should be the expected string.");
    XCTAssertEqualObjects(@"755224", [token generatePasswordForCounter:0], @"The generatePasswordForCounter: method should be idempotent.");

    NSArray *expectedValues = @[@"287082",
                                @"359152",
                                @"969429",
                                @"338314",
                                @"254676",
                                @"287922",
                                @"162583",
                                @"399871",
                                @"520489"];

    token.counter = 0;
    for (NSString *expectedPassword in expectedValues) {
        [token updatePassword];
        XCTAssertEqualObjects(token.password, expectedPassword, @"The generator did not produce the expected OTP.");
    }
}

// The values in this test are found in Appendix B of the TOTP RFC
// https://tools.ietf.org/html/rfc6238#appendix-B
- (void)testTOTPRFCValues
{
    NSDictionary *secretKeys = @{@(OTPAlgorithmSHA1):   @"12345678901234567890",
                                 @(OTPAlgorithmSHA256): @"12345678901234567890123456789012",
                                 @(OTPAlgorithmSHA512): @"1234567890123456789012345678901234567890123456789012345678901234"};

    NSArray *times = @[@59,
                       @1111111109,
                       @1111111111,
                       @1234567890,
                       @2000000000,
                       @20000000000];

    NSDictionary *expectedValues = @{@(OTPAlgorithmSHA1):   @[@"94287082", @"07081804", @"14050471", @"89005924", @"69279037", @"65353130"],
                                     @(OTPAlgorithmSHA256): @[@"46119246", @"68084774", @"67062674", @"91819424", @"90698825", @"77737706"],
                                     @(OTPAlgorithmSHA512): @[@"90693936", @"25091201", @"99943326", @"93441116", @"38618901", @"47863826"]};

    for (NSNumber *algorithmKey in secretKeys) {
        NSData *secret = [secretKeys[algorithmKey] dataUsingEncoding:NSASCIIStringEncoding];
        OTPToken *token = [[OTPToken alloc] initWithType:OTPTokenTypeTimer
                                                  secret:secret
                                                    name:@""
                                                  issuer:@""
                                               algorithm:[algorithmKey integerValue]
                                                  digits:8
                                                  period:30];

        for (NSUInteger i = 0; i < times.count; i++) {
            NSString *password = expectedValues[algorithmKey][i];
            XCTAssertEqualObjects([token generatePasswordForCounter:([times[i] doubleValue] / token.period)], password, @"The generator did not produce the expected OTP.");
        }
    }
}

// From Google Authenticator for iOS
// https://code.google.com/p/google-authenticator/source/browse/mobile/ios/Classes/TOTPGeneratorTest.m
- (void)testTOTPGoogleValues
{
    NSData *secret = [@"12345678901234567890" dataUsingEncoding:NSASCIIStringEncoding];

    NSTimeInterval intervals[] = { 1111111111, 1234567890, 2000000000 };

    NSArray *algorithms = @[@(OTPAlgorithmSHA1),
                            @(OTPAlgorithmSHA256),
                            @(OTPAlgorithmSHA512),
                            ];
    NSArray *results = @[// SHA1      SHA256     SHA512
                         @"050471", @"584430", @"380122", // date1
                         @"005924", @"829826", @"671578", // date2
                         @"279037", @"428693", @"464532", // date3
                         ];

    for (unsigned int i = 0, j = 0; i < sizeof(intervals)/sizeof(*intervals); i++) {
        for (NSNumber *algorithmKey in algorithms) {
            OTPToken *token = [[OTPToken alloc] initWithType:OTPTokenTypeTimer
                                                      secret:secret
                                                        name:@""
                                                      issuer:@""
                                                   algorithm:[algorithmKey integerValue]
                                                      digits:6
                                                      period:30];

            XCTAssertEqualObjects([results objectAtIndex:j],
                                  [token generatePasswordForCounter:(intervals[i] / token.period)],
                                  @"Invalid result %d, %@, %f", i, algorithmKey, intervals[i]);
            j++;
        }
    }
}

@end
