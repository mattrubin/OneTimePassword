//
//  OTPSecurity.m
//  OneTimePassword
//
//  Created by Matt Rubin on 7/10/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

@import Security.SecItem;

id _kSecAttrGeneric() {
    return (__bridge id)(kSecAttrGeneric);
}
id _kSecValueData() {
    return (__bridge id)(kSecValueData);
}
id _kSecValuePersistentRef() {
    return (__bridge id)(kSecValuePersistentRef);
}
