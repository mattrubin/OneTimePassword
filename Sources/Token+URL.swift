//
//  Token+URL.swift
//  OneTimePassword
//
//  Copyright (c) 2014-2016 Matt Rubin and the OneTimePassword authors
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
import Base32

extension Token {
    // MARK: Serialization

    /// Serializes the token to a URL.
    public func toURL() throws -> URL {
        return try urlForToken(
            name: name,
            issuer: issuer,
            factor: generator.factor,
            algorithm: generator.algorithm,
            digits: generator.digits
        )
    }

    /// Attempts to initialize a token represented by the give URL.
    public init?(url: URL, secret: Data? = nil) {
        if let token = tokenFromURL(url, secret: secret) {
            self = token
        } else {
            return nil
        }
    }
}

internal enum SerializationError: ErrorProtocol {
    case URLGenerationFailure
}

private let defaultAlgorithm: Generator.Algorithm = .SHA1
private let defaultDigits: Int = 6
private let defaultCounter: UInt64 = 0
private let defaultPeriod: TimeInterval = 30

private let kOTPAuthScheme = "otpauth"
private let kQueryAlgorithmKey = "algorithm"
private let kQuerySecretKey = "secret"
private let kQueryCounterKey = "counter"
private let kQueryDigitsKey = "digits"
private let kQueryPeriodKey = "period"
private let kQueryIssuerKey = "issuer"

private let kFactorCounterKey = "hotp"
private let kFactorTimerKey = "totp"

private let kAlgorithmSHA1   = "SHA1"
private let kAlgorithmSHA256 = "SHA256"
private let kAlgorithmSHA512 = "SHA512"

private func stringForAlgorithm(algorithm: Generator.Algorithm) -> String {
    switch algorithm {
    case .SHA1:   return kAlgorithmSHA1
    case .SHA256: return kAlgorithmSHA256
    case .SHA512: return kAlgorithmSHA512
    }
}

private func algorithmFromString(string: String) -> Generator.Algorithm? {
    if string == kAlgorithmSHA1 { return .SHA1 }
    if string == kAlgorithmSHA256 { return .SHA256 }
    if string == kAlgorithmSHA512 { return .SHA512 }
    return nil
}

private func urlForToken(name name: String, issuer: String, factor: Generator.Factor, algorithm: Generator.Algorithm, digits: Int) throws -> URL {
    let urlComponents = URLComponents()
    urlComponents.scheme = kOTPAuthScheme
    urlComponents.path = "/" + name

    var queryItems = [
        URLQueryItem(name:kQueryAlgorithmKey, value:stringForAlgorithm(algorithm)),
        URLQueryItem(name:kQueryDigitsKey, value:String(digits)),
        URLQueryItem(name:kQueryIssuerKey, value:issuer)
    ]

    switch factor {
    case .Timer(let period):
        urlComponents.host = kFactorTimerKey
        queryItems.append(URLQueryItem(name:kQueryPeriodKey, value:String(Int(period))))
    case .Counter(let counter):
        urlComponents.host = kFactorCounterKey
        queryItems.append(URLQueryItem(name:kQueryCounterKey, value:String(counter)))
    }

    urlComponents.queryItems = queryItems

    guard let url = urlComponents.URL else {
        throw SerializationError.URLGenerationFailure
    }
    return url
}

private func tokenFromURL(url: URL, secret externalSecret: Data? = nil) -> Token? {
    guard url.scheme == kOTPAuthScheme else {
        return nil
    }

    var queryDictionary = Dictionary<String, String>()
    URLComponents(URL: url, resolvingAgainstBaseURL: false)?.queryItems?.forEach { item in
        queryDictionary[item.name] = item.value
    }

    let factorParser: (string: String) -> Generator.Factor? = { string in
        if string == kFactorCounterKey {
            if let counter: UInt64 = parse(queryDictionary[kQueryCounterKey],
                with: {
                    errno = 0
                    let counterValue = strtoull(($0 as NSString).UTF8String, nil, 10)
                    guard errno == 0 else {
                        return nil
                    }
                    return counterValue
                },
                defaultTo: defaultCounter) {
                    return .Counter(counter)
            }
        } else if string == kFactorTimerKey {
            if let period: TimeInterval = parse(queryDictionary[kQueryPeriodKey],
                with: {
                    guard let int = Int($0) else {
                        return nil
                    }
                    return TimeInterval(int)
                },
                defaultTo: defaultPeriod) {
                    return .Timer(period: period)
            }
        }
        return nil
    }

    guard let factor = parse(url.host, with: factorParser, defaultTo: nil),
        let secret = parse(queryDictionary[kQuerySecretKey], with: { MF_Base32Codec.dataFromBase32String($0) }, overrideWith: externalSecret),
        let algorithm = parse(queryDictionary[kQueryAlgorithmKey], with: algorithmFromString, defaultTo: defaultAlgorithm),
        let digits = parse(queryDictionary[kQueryDigitsKey], with: { Int($0) }, defaultTo: defaultDigits),
        let generator = Generator(factor: factor, secret: secret, algorithm: algorithm, digits: digits) else {
            return nil
    }

    var name = Token.defaultName
    if let path = url.path {
        if path.characters.count > 1 {
            name = path.substringFromIndex(path.startIndex.successor()) // Skip the leading "/"
        }
    }

    var issuer = Token.defaultIssuer
    if let issuerString = queryDictionary[kQueryIssuerKey] {
        issuer = issuerString
    } else {
        // If there is no issuer string, try to extract one from the name
        let components = name.componentsSeparatedByString(":")
        if components.count > 1 {
            issuer = components[0]
        }
    }
    // If the name is prefixed by the issuer string, trim the name
    if !issuer.isEmpty {
        let prefix = issuer + ":"
        if name.hasPrefix(prefix), let prefixRange = name.rangeOfString(prefix) {
            name = name.substringFromIndex(prefixRange.endIndex)
            name = name.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        }
    }

    return Token(name: name, issuer: issuer, generator: generator)
}

private func parse<P, T>(item: P?, with parser: (P -> T?), defaultTo defaultValue: T? = nil, overrideWith overrideValue: T? = nil) -> T? {
    if let value = overrideValue {
        return value
    }

    if let concrete = item {
        guard let value = parser(concrete) else {
            return nil
        }
        return value
    }
    return defaultValue
}
