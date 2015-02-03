//
//  OTPTokenTests.m
//  OneTimePassword
//
//  Created by Matt Rubin on 2/3/15.
//  Copyright (c) 2015 Matt Rubin. All rights reserved.
//

@import XCTest;
@import OneTimePasswordLegacy;


@interface OTPTokenTests : XCTestCase
@end


@implementation OTPTokenTests

- (void)testDefaults
{
    XCTAssertEqual([OTPToken defaultAlgorithm], OTPAlgorithmSHA1);
    XCTAssertEqual([OTPToken defaultDigits], 6U);
    XCTAssertEqual([OTPToken defaultInitialCounter], 0UL);
    XCTAssertEqual([OTPToken defaultPeriod], 30);
}

- (void)testInit
{
    OTPToken *token = [[OTPToken alloc] init];

    XCTAssertEqualObjects(token.name, @"");
    XCTAssertEqualObjects(token.issuer, @"");
    XCTAssertEqual(token.type, OTPTokenTypeTimer);
    XCTAssertEqualObjects(token.secret, [NSData new]);
    XCTAssertEqual(token.algorithm, OTPAlgorithmSHA1);
    XCTAssertEqual(token.digits, 6U);
    XCTAssertEqual(token.period, 30);
    XCTAssertEqual(token.counter, 0UL);
}

@end
