//
//  TokenSerializer.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 8/23/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import Foundation

public protocol TokenSerializer {
    static func serialize(token: Token) -> String?
    static func deserialize(string: String, secret: NSData?) -> Token?
}
