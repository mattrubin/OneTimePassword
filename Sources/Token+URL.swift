//
//  Token+URL.swift
//  OneTimePassword
//
//  Copyright (c) 2014-2017 Matt Rubin and the OneTimePassword authors
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
        do {
        if let token = try token(from: url, secret: secret) {
            self = token
        } else {
            return nil
        }
        } catch {
            return nil
        }
    }
}

internal enum SerializationError: Swift.Error {
    case urlGenerationFailure
}

internal enum DeserializationError: Swift.Error {
    case factor
    case counterValue
    case timerPeriod
    case secret
    case algorithm
    case digits
}

private let defaultAlgorithm: Generator.Algorithm = .sha1
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

private func stringForAlgorithm(_ algorithm: Generator.Algorithm) -> String {
    switch algorithm {
    case .sha1:
        return kAlgorithmSHA1
    case .sha256:
        return kAlgorithmSHA256
    case .sha512:
        return kAlgorithmSHA512
    }
}

private func algorithmFromString(_ string: String) throws -> Generator.Algorithm {
    switch string {
    case kAlgorithmSHA1:
        return .sha1
    case kAlgorithmSHA256:
        return .sha256
    case kAlgorithmSHA512:
        return .sha512
    default:
        throw DeserializationError.algorithm
    }
}

private func urlForToken(name: String, issuer: String, factor: Generator.Factor, algorithm: Generator.Algorithm, digits: Int) throws -> URL {
    var urlComponents = URLComponents()
    urlComponents.scheme = kOTPAuthScheme
    urlComponents.path = "/" + name

    var queryItems = [
        URLQueryItem(name: kQueryAlgorithmKey, value: stringForAlgorithm(algorithm)),
        URLQueryItem(name: kQueryDigitsKey, value: String(digits)),
        URLQueryItem(name: kQueryIssuerKey, value: issuer),
    ]

    switch factor {
    case .timer(let period):
        urlComponents.host = kFactorTimerKey
        queryItems.append(URLQueryItem(name: kQueryPeriodKey, value: String(Int(period))))
    case .counter(let counter):
        urlComponents.host = kFactorCounterKey
        queryItems.append(URLQueryItem(name: kQueryCounterKey, value: String(counter)))
    }

    urlComponents.queryItems = queryItems

    guard let url = urlComponents.url else {
        throw SerializationError.urlGenerationFailure
    }
    return url
}

private func token(from url: URL, secret externalSecret: Data? = nil) throws -> Token? {
    guard url.scheme == kOTPAuthScheme else {
        return nil
    }

    var queryDictionary = Dictionary<String, String>()
    URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.forEach { item in
        queryDictionary[item.name] = item.value
    }

    let factorParser: (String) throws -> Generator.Factor = { string in
        if string == kFactorCounterKey {
            let counter = try queryDictionary[kQueryCounterKey].map(parseCounterValue) ?? defaultCounter
            return .counter(counter)
        } else if string == kFactorTimerKey {
            let period = try queryDictionary[kQueryPeriodKey].map(parseTimerPeriod) ?? defaultPeriod
            return .timer(period: period)
        }
        throw DeserializationError.factor
    }

    let algorithm = try queryDictionary[kQueryAlgorithmKey].map(algorithmFromString) ?? defaultAlgorithm
    let digits = try queryDictionary[kQueryDigitsKey].map(parseDigits) ?? defaultDigits

    guard let factor = try url.host.map(factorParser),
        let secret = try externalSecret ?? queryDictionary[kQuerySecretKey].map(parseSecret),
        let generator = Generator(factor: factor, secret: secret, algorithm: algorithm, digits: digits) else {
            return nil
    }

    // Skip the leading "/"
    var name = String(url.path.dropFirst())

    let issuer: String
    if let issuerString = queryDictionary[kQueryIssuerKey] {
        issuer = issuerString
    } else if let separatorRange = name.range(of: ":") {
        // If there is no issuer string, try to extract one from the name
        issuer = String(name[..<separatorRange.lowerBound])
    } else {
        // The default value is an empty string
        issuer = ""
    }

    // If the name is prefixed by the issuer string, trim the name
    if !issuer.isEmpty {
        let prefix = issuer + ":"
        if name.hasPrefix(prefix), let prefixRange = name.range(of: prefix) {
            let substringAfterSeparator = name[prefixRange.upperBound...]
            name = substringAfterSeparator.trimmingCharacters(in: CharacterSet.whitespaces)
        }
    }

    return Token(name: name, issuer: issuer, generator: generator)
}

private func parseCounterValue(_ rawValue: String) throws -> UInt64 {
    guard let counterValue = UInt64(rawValue, radix: 10) else {
        throw DeserializationError.counterValue
    }
    return counterValue
}

private func parseTimerPeriod(_ rawValue: String) throws -> TimeInterval {
    guard let int = Int(rawValue) else {
        throw DeserializationError.timerPeriod
    }
    return TimeInterval(int)
}

private func parseSecret(_ rawValue: String) throws -> Data {
    guard let data = MF_Base32Codec.data(fromBase32String: rawValue) else {
        throw DeserializationError.secret
    }
    return data
}

private func parseDigits(_ rawValue: String) throws -> Int {
    guard let intValue = Int(rawValue) else {
        throw DeserializationError.digits
    }
    return intValue
}
