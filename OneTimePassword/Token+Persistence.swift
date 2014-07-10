//
//  Token+Persistence.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/9/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

extension Token {
    struct KeychainWrapper {
        let token: Token
        let keychainItemRef: NSData? // TODO: make this a required constant
    }
}
