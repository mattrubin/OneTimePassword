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

}


@end
