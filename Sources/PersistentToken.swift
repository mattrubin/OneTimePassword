//
//  PersistentToken.swift
//  OneTimePassword
//
//  Copyright (c) 2014-2018 Matt Rubin and the OneTimePassword authors
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

import Foundation

/// A `PersistentToken` represents a `Token` stored in the `Keychain`. The keychain assigns each
/// saved `token` a unique `identifier` which can be used to recover the token from the keychain at
/// a later time.
public struct PersistentToken: Equatable, Hashable {
    /// A `Token` stored in the keychain.
    public let token: Token
    /// The keychain's persistent identifier for the saved token.
    public let identifier: Data

    /// Initializes a new `PersistentToken` with the given properties.
    internal init(token: Token, identifier: Data) {
        self.token = token
        self.identifier = identifier
    }

    /// Hashes the persistent token's identifier into the given hasher, providing `Hashable` conformance.
    public func hash(into hasher: inout Hasher) {
        // Since we expect every `PersistentToken`s identifier to be unique, the identifier's hash
        // value makes a simple and adequate hash value for the struct as a whole.
        hasher.combine(identifier)
    }
}
