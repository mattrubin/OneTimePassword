//
//  OTPToken.swift
//  OneTimePassword
//
//  Copyright (c) 2013-2016 Matt Rubin and the OneTimePassword authors
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
import OneTimePassword

/// `OTPToken` is a mutable, Objective-C-compatible wrapper around `OneTimePassword.Token`. For more
/// information about its properties and methods, consult the underlying `OneTimePassword`
/// documentation.
public final class OTPToken: NSObject {
    required public override init() {}

    public var name: String = OTPToken.defaultName
    public var issuer: String = OTPToken.defaultIssuer
    public var type: OTPTokenType = .timer
    public var secret: Data = Data()
    public var algorithm: OTPAlgorithm = OTPToken.defaultAlgorithm
    public var digits: UInt = OTPToken.defaultDigits
    public var period: TimeInterval = OTPToken.defaultPeriod
    public var counter: UInt64 = OTPToken.defaultInitialCounter

    private static let defaultName: String = ""
    private static let defaultIssuer: String = ""
    private static let defaultAlgorithm: OTPAlgorithm = .sha1
    private static var defaultDigits: UInt = 6
    private static var defaultInitialCounter: UInt64 = 0
    private static var defaultPeriod: TimeInterval = 30

    private func update(with token: Token) {
        self.name = token.name
        self.issuer = token.issuer

        self.secret = token.generator.secret
        self.algorithm = OTPAlgorithm(token.generator.algorithm)
        self.digits = UInt(token.generator.digits)

        switch token.generator.factor {
        case let .counter(counter):
            self.type = .counter
            self.counter = counter
        case let .timer(period):
            self.type = .timer
            self.period = period
        }
    }

    fileprivate convenience init(token: Token) {
        self.init()
        update(with: token)
    }

    public func validate() -> Bool {
        return (tokenForOTPToken(self) != nil)
    }
}

public extension OTPToken {
    @objc(tokenWithURL:)
    static func token(from url: URL) -> Self? {
        return token(from: url, secret: nil)
    }

    @objc(tokenWithURL:secret:)
    static func token(from url: URL, secret: Data?) -> Self? {
        guard let token = Token(url: url, secret: secret) else {
            return nil
        }
        return self.init(token: token)
    }

    func url() -> URL? {
        guard let token = tokenForOTPToken(self) else {
            return nil
        }
        return try? token.toURL()
    }
}

// MARK: Enums

@objc
public enum OTPTokenType: UInt8 {
    case counter
    case timer
}

@objc
public enum OTPAlgorithm: UInt32 {
    @objc(OTPAlgorithmSHA1)   case sha1
    @objc(OTPAlgorithmSHA256) case sha256
    @objc(OTPAlgorithmSHA512) case sha512
}

// MARK: Conversion

private extension OTPAlgorithm {
    init(_ generatorAlgorithm: Generator.Algorithm) {
        switch generatorAlgorithm {
        case .sha1:
            self = .sha1
        case .sha256:
            self = .sha256
        case .sha512:
            self = .sha512
        }
    }
}

private func tokenForOTPToken(_ otpToken: OTPToken) -> Token? {
    guard let generator = Generator(
        factor: factorForOTPToken(otpToken),
        secret: otpToken.secret,
        algorithm: algorithmForOTPAlgorithm(otpToken.algorithm),
        digits: Int(otpToken.digits)
        ) else {
            return nil
    }
    return Token(name: otpToken.name, issuer: otpToken.issuer, generator: generator)
}

private func factorForOTPToken(_ otpToken: OTPToken) -> Generator.Factor {
    switch otpToken.type {
    case .counter:
        return .counter(otpToken.counter)
    case .timer:
        return .timer(period: otpToken.period)
    }
}

private func algorithmForOTPAlgorithm(_ algorithm: OTPAlgorithm) -> Generator.Algorithm {
    switch algorithm {
    case .sha1:
        return .sha1
    case .sha256:
        return .sha256
    case .sha512:
        return .sha512
    }
}
