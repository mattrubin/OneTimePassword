//
//  TokenSerializer.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 8/23/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import Foundation

public protocol TokenSerializer {
    typealias SerializedToken
    static func serialize(token: Token) -> SerializedToken?
    static func deserialize(serializedToken: SerializedToken, secret: NSData?) -> Token?
}
