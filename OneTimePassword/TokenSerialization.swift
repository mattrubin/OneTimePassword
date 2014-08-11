//
//  TokenSerialization.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/8/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import Foundation

let kOTPAuthScheme = "otpauth"
let kQueryAlgorithmKey = "algorithm"
let kQuerySecretKey = "secret"
let kQueryCounterKey = "counter"
let kQueryDigitsKey = "digits"
let kQueryPeriodKey = "period"
let kQueryIssuerKey = "issuer"

let FactorCounterString = "hotp"
let FactorTimerString = "totp"

let kAlgorithmSHA1   = "SHA1"
let kAlgorithmSHA256 = "SHA256"
let kAlgorithmSHA512 = "SHA512"

func stringForAlgorithm(algorithm: Generator.Algorithm) -> String {
    switch algorithm {
    case .SHA1:   return kAlgorithmSHA1
    case .SHA256: return kAlgorithmSHA256
    case .SHA512: return kAlgorithmSHA512
    }
}

func algorithmFromString(string: String) -> Generator.Algorithm? {
    if (string == kAlgorithmSHA1) { return .SHA1 }
    if (string == kAlgorithmSHA256) { return .SHA256 }
    if (string == kAlgorithmSHA512) { return .SHA512 }
    return nil
}

func urlForToken(#name: String, #issuer: String, #factor: Generator.Factor, #algorithm: Generator.Algorithm, #digits: Int) -> NSURL {
    let urlComponents = NSURLComponents()
    urlComponents.scheme = kOTPAuthScheme
    urlComponents.path = "/" + name

    urlComponents.queryItems = [
        NSURLQueryItem(name:kQueryAlgorithmKey, value:stringForAlgorithm(algorithm)),
        NSURLQueryItem(name:kQueryDigitsKey, value:String(digits)),
        NSURLQueryItem(name:kQueryIssuerKey, value:issuer)
    ]

    switch factor {
    case .Timer(let period):
        urlComponents.host = FactorTimerString
        urlComponents.queryItems.append(NSURLQueryItem(name:kQueryPeriodKey, value:String(Int(period))))
    case .Counter(let counter):
        urlComponents.host = FactorCounterString
        urlComponents.queryItems.append(NSURLQueryItem(name:kQueryCounterKey, value:String(counter)))
    }

    return urlComponents.URL
}

func tokenFromURL(url: NSURL, secret externalSecret: NSData? = nil) -> Token? {
    if (url.scheme != kOTPAuthScheme) { return nil }

    var queryDictionary = Dictionary<String, String>()
    if let queryItems = NSURLComponents(URL:url, resolvingAgainstBaseURL:false).queryItems as? [NSURLQueryItem] {
        for item in queryItems {
            queryDictionary[item.name] = item.value
        }
    }

    let factorParser: (string: String) -> Generator.Factor? = { string in
        if string == FactorCounterString {
            if let counter: UInt64 = parse(queryDictionary[kQueryCounterKey], with: {
                errno = 0
                let counterValue = strtoull(($0 as NSString).UTF8String, nil, 10)
                if errno == 0 {
                    return counterValue
                }
                return nil
                }, defaultTo: 0)
            {
                return .Counter(counter)
            }
        } else if string == FactorTimerString {
            if let period: NSTimeInterval = parse(queryDictionary[kQueryPeriodKey], with: {
                if let int = $0.toInt() {
                    return NSTimeInterval(int)
                }
                return nil
                }, defaultTo: 30)
            {
                return .Timer(period: period)
            }
        }
        return nil
    }

    if let factor = parse(url.host, with: factorParser, defaultTo: nil) {
        if let secret = parse(queryDictionary[kQuerySecretKey], with: { MF_Base32Codec.dataFromBase32String($0) }, overrideWith: externalSecret) {
            if let algorithm = parse(queryDictionary[kQueryAlgorithmKey], with: algorithmFromString, defaultTo: .SHA1) {
                if let digits = parse(queryDictionary[kQueryDigitsKey], with: { $0.toInt() }, defaultTo: 6) {
                    let core = Generator(factor: factor, secret: secret, algorithm: algorithm, digits: digits)

                    if core.isValid {
                        var name = ""
                        if let path = url.path {
                            if countElements(path) > 1 {
                                name = path.substringFromIndex(path.startIndex.successor()) // Skip the leading "/"
                            }
                        }

                        var issuer = ""
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
                            if (prefixRange.startIndex == issuer.startIndex) && (countElements(issuer) < countElements(name)) && (name[prefixRange.endIndex] == ":") {
                                name = name.substringFromIndex(prefixRange.endIndex.successor()).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                            }
                        }

                        return Token(name: name, issuer: issuer, core: core)
                    }
                }
            }
        }
    }
    return nil
}

func parse<P, T>(item: P?, with parser: (P -> T?), defaultTo defaultValue: T? = nil, overrideWith overrideValue: T? = nil) -> T? {
    if let value = overrideValue {
        return value
    }

    if let concrete = item {
        if let value = parser(concrete) {
            return value
        }
        return nil
    }
    return defaultValue
}
