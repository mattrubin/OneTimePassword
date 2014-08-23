//
//  TokenSerializer.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 8/23/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

public protocol TokenSerializer {
    class func serialize(token: Token) -> String?
    class func deserialize(string: String, secret: NSData?) -> Token?
}
