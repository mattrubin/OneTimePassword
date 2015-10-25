//
//  Token.URLSerializer.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/8/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import Foundation
import Base32

extension Token {
    public struct URLSerializer: TokenSerializer {
        public static func serialize(token: Token) -> String? {
            let url = urlForToken(name: token.name, issuer: token.issuer, factor: token.core.factor, algorithm: token.core.algorithm, digits: token.core.digits)
            return url?.absoluteString
        }

        public static func deserialize(string: String, secret: NSData? = nil) -> Token? {
            guard let url = NSURL(string: string)
                else { return nil }
            return tokenFromURL(url, secret: secret)
        }
    }
}


private let kOTPAuthScheme = "otpauth"
private let kQueryAlgorithmKey = "algorithm"
private let kQuerySecretKey = "secret"
private let kQueryCounterKey = "counter"
private let kQueryDigitsKey = "digits"
private let kQueryPeriodKey = "period"
private let kQueryIssuerKey = "issuer"

private let FactorCounterString = "hotp"
private let FactorTimerString = "totp"

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
    if (string == kAlgorithmSHA1) { return .SHA1 }
    if (string == kAlgorithmSHA256) { return .SHA256 }
    if (string == kAlgorithmSHA512) { return .SHA512 }
    return nil
}

private func urlForToken(name name: String, issuer: String, factor: Generator.Factor, algorithm: Generator.Algorithm, digits: Int) -> NSURL? {
    let urlComponents = NSURLComponents()
    urlComponents.scheme = kOTPAuthScheme
    urlComponents.path = "/" + name

    var queryItems = [
        NSURLQueryItem(name:kQueryAlgorithmKey, value:stringForAlgorithm(algorithm)),
        NSURLQueryItem(name:kQueryDigitsKey, value:String(digits)),
        NSURLQueryItem(name:kQueryIssuerKey, value:issuer)
    ]

    switch factor {
    case .Timer(let period):
        urlComponents.host = FactorTimerString
        queryItems.append(NSURLQueryItem(name:kQueryPeriodKey, value:String(Int(period))))
    case .Counter(let counter):
        urlComponents.host = FactorCounterString
        queryItems.append(NSURLQueryItem(name:kQueryCounterKey, value:String(counter)))
    }

    urlComponents.queryItems = queryItems

    return urlComponents.URL
}

private func tokenFromURL(url: NSURL, secret externalSecret: NSData? = nil) -> Token? {
    guard url.scheme == kOTPAuthScheme
        else { return nil }

    var queryDictionary = Dictionary<String, String>()
    NSURLComponents(URL: url, resolvingAgainstBaseURL: false)?.queryItems?.forEach { item in
        queryDictionary[item.name] = item.value
    }

    let factorParser: (string: String) -> Generator.Factor? = { string in
        if string == FactorCounterString {
            if let counter: UInt64 = parse(queryDictionary[kQueryCounterKey], with: {
                errno = 0
                let counterValue = strtoull(($0 as NSString).UTF8String, nil, 10)
                guard errno == 0
                    else { return nil }
                return counterValue
                }, defaultTo: 0)
            {
                return .Counter(counter)
            }
        } else if string == FactorTimerString {
            if let period: NSTimeInterval = parse(queryDictionary[kQueryPeriodKey], with: {
                guard let int = Int($0)
                    else { return nil }
                return NSTimeInterval(int)
                }, defaultTo: 30)
            {
                return .Timer(period: period)
            }
        }
        return nil
    }

    guard let factor = parse(url.host, with: factorParser, defaultTo: nil),
        let secret = parse(queryDictionary[kQuerySecretKey], with: { MF_Base32Codec.dataFromBase32String($0) }, overrideWith: externalSecret),
        let algorithm = parse(queryDictionary[kQueryAlgorithmKey], with: algorithmFromString, defaultTo: Generator.defaultAlgorithm),
        let digits = parse(queryDictionary[kQueryDigitsKey], with: { Int($0) }, defaultTo: Generator.defaultDigits),
        let core = Generator(factor: factor, secret: secret, algorithm: algorithm, digits: digits)
        else { return nil }

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
    if let prefixRange = name.rangeOfString(issuer) {
        if (prefixRange.startIndex == issuer.startIndex) && (issuer.characters.count < name.characters.count) && (name[prefixRange.endIndex] == ":") {
            name = name.substringFromIndex(prefixRange.endIndex.successor()).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        }
    }

    return Token(name: name, issuer: issuer, core: core)
}

private func parse<P, T>(item: P?, with parser: (P -> T?), defaultTo defaultValue: T? = nil, overrideWith overrideValue: T? = nil) -> T? {
    if let value = overrideValue {
        return value
    }

    if let concrete = item {
        guard let value = parser(concrete)
            else { return nil }
        return value
    }
    return defaultValue
}
