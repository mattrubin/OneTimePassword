//
//  Token+Serialization.swift
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

func algorithmFromString(string: String?) -> Generator.Algorithm? {
    if (string == kAlgorithmSHA1) { return .SHA1 }
    if (string == kAlgorithmSHA256) { return .SHA256 }
    if (string == kAlgorithmSHA512) { return .SHA512 }
    return nil
}

func urlForToken(token: Token) -> NSURL
{
    let urlComponents = NSURLComponents()
    urlComponents.scheme = kOTPAuthScheme
    urlComponents.path = "/" + token.name

    urlComponents.queryItems = [
        NSURLQueryItem(name:kQueryAlgorithmKey, value:stringForAlgorithm(token.core.algorithm)),
        NSURLQueryItem(name:kQueryDigitsKey, value:String(token.core.digits)),
        NSURLQueryItem(name:kQueryIssuerKey, value:token.issuer)
    ]

    switch token.core.factor {
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
    if let queryItems = NSURLComponents(URL:url, resolvingAgainstBaseURL:false).queryItems {
        for object : AnyObject in queryItems {
            if let item = object as? NSURLQueryItem {
                queryDictionary[item.name] = item.value
            }
        }
    }


    var name = ""
    if let path = url.path {
        if countElements(path) > 1 {
            name = path.substringFromIndex(path.startIndex.successor()) // Skip the leading "/"
        }
    }

    var issuer = ""
    if let issuerString = queryDictionary[kQueryIssuerKey] {
        issuer = issuerString
        // If the name is prefixed by the issuer string, trim the name
        if let prefixRange = name.rangeOfString(issuer) {
            if (prefixRange.startIndex == issuer.startIndex) && (countElements(issuer) < countElements(name)) && (name[prefixRange.endIndex] == ":") {
                name = name.substringFromIndex(prefixRange.endIndex.successor()).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            }
        }
    } else {
        // If there is no issuer string, try to extract one from the name
        let components = name.componentsSeparatedByString(":")
        if components.count > 1 {
            issuer = components[0]
            // If the name is prefixed by the issuer string, trim the name
            if let prefixRange = name.rangeOfString(issuer) {
                if (prefixRange.startIndex == issuer.startIndex) && (countElements(issuer) < countElements(name)) && (name[prefixRange.endIndex] == ":") {
                    name = name.substringFromIndex(prefixRange.endIndex.successor()).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                }
            }
        }
    }

    if let core = generatorFromStrings(url.host, queryDictionary[kQuerySecretKey], queryDictionary[kQueryAlgorithmKey], queryDictionary[kQueryDigitsKey], queryDictionary[kQueryCounterKey], queryDictionary[kQueryPeriodKey], externalSecret) {
        if core.isValid {
            return Token(name: name, issuer: issuer, core: core)
        }
    }
    return nil
}


func generatorFromStrings(_factorString: String?, _secretString: String?, _algorithmString: String?, _digitsString: String?, _counterString: String?, _periodString: String?, externalSecret: NSData?) -> Generator? {

    func counterParser(string: String) -> UInt64? {
        errno = 0
        let counterValue = strtoull((string as NSString).UTF8String, nil, 10)
        if errno == 0 {
            return counterValue
        }
        return nil
    }

    func parse<T>(raw: String?, parse: (String -> T?)) -> ParseResult<T> {
        if let string = raw {
            if let value = parse(string) {
                return .Result(value)
            } else {
                return .Error
            }
        }
        return .Default
    }

    func periodParser(string: String) -> NSTimeInterval? {
        if let int = string.toInt() {
            return NSTimeInterval(int)
        }
        return nil
    }

    func secretParser(string: String) -> NSData? {
        return MF_Base32Codec.dataFromBase32String(string)
    }

    func algorithmParser(string: String) -> Generator.Algorithm? {
        return algorithmFromString(string)
    }

    func digitsParser(string: String) -> Int? {
        return string.toInt()
    }

    func factorParser(parsedCounter: ParseResult<UInt64>, parsedPeriod: ParseResult<NSTimeInterval>) -> (string: String) -> Generator.Factor? {
        return { string in
        if string == FactorCounterString {
            if let counter = parsedCounter.defaultTo(0) {
                return .Counter(counter)
            }
        } else if string == FactorTimerString {
            if let period =  parsedPeriod.defaultTo(30) {
                return .Timer(period: period)
            }
        }
        return nil
        }
    }

    if let factor = parse(_factorString, factorParser(parse(_counterString, counterParser), parse(_periodString, periodParser))).defaultTo(nil) {
        if let secret = parse(_secretString, secretParser).overrideWith(externalSecret) {
            if let algorithm = parse(_algorithmString, algorithmParser).defaultTo(.SHA1) {
                if let digits = parse(_digitsString, digitsParser).defaultTo(6) {
                    return Generator(factor: factor, secret: secret, algorithm: algorithm, digits: digits)
                }
            }
        }
    }
    return nil
}

enum ParseResult<T> {
    case Default
    case Error
    case Result(T)

    func defaultTo(d: T?) -> T? {
        switch self {
        case .Default:
            return d
        case .Result(let value):
            return value
        case .Error:
            return nil
        }
    }

    func overrideWith(possibleOverride: T?) -> T? {
        if let concreteValue = possibleOverride {
            return concreteValue
        }
        return self.defaultTo(possibleOverride)
    }
}
