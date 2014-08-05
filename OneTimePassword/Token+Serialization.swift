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

let TokenTypeCounterString = "hotp"
let TokenTypeTimerString = "totp"

let kAlgorithmSHA1   = "SHA1"
let kAlgorithmSHA256 = "SHA256"
let kAlgorithmSHA512 = "SHA512"

func stringForAlgorithm(algorithm: Token.Algorithm) -> String {
    switch algorithm {
    case .SHA1:   return kAlgorithmSHA1
    case .SHA256: return kAlgorithmSHA256
    case .SHA512: return kAlgorithmSHA512
    }
}

func algorithmFromString(string: String?) -> Token.Algorithm? {
    if (string == kAlgorithmSHA1) { return .SHA1 }
    if (string == kAlgorithmSHA256) { return .SHA256 }
    if (string == kAlgorithmSHA512) { return .SHA512 }
    return nil
}


public extension Token {
    var url: NSURL {
        let urlComponents = NSURLComponents()
        urlComponents.scheme = kOTPAuthScheme

        switch type {
        case .Counter:
            urlComponents.host = TokenTypeCounterString
        case .Timer:
            urlComponents.host = TokenTypeTimerString
        }

        urlComponents.path = "/" + name

        urlComponents.queryItems = [
            NSURLQueryItem(name:kQueryAlgorithmKey, value:stringForAlgorithm(algorithm)),
            NSURLQueryItem(name:kQueryDigitsKey, value:String(digits)),
            NSURLQueryItem(name:kQueryIssuerKey, value:issuer)
        ]

        switch type {
        case .Timer(let period):
            urlComponents.queryItems.append(NSURLQueryItem(name:kQueryPeriodKey, value:String(Int(period))))
        case .Counter(let counter):
            urlComponents.queryItems.append(NSURLQueryItem(name:kQueryCounterKey, value:String(counter)))
        }

        return urlComponents.URL
    }

    static func tokenWithURL(url: NSURL, secret externalSecret: NSData? = nil) -> Token? {
        if (url.scheme != kOTPAuthScheme) { return nil }

        var queryDictionary = Dictionary<String, String>()
        if let queryItems = NSURLComponents(URL:url, resolvingAgainstBaseURL:false).queryItems {
            for object : AnyObject in queryItems {
                if let item = object as? NSURLQueryItem {
                    queryDictionary[item.name] = item.value
                }
            }
        }

        var type: TokenType?
        if let host = url.host {
            if host == TokenTypeCounterString {
                type = TokenType.Counter(0)
                if let counterString = queryDictionary[kQueryCounterKey] {
                    errno = 0
                    let counterValue = strtoull((counterString as NSString).UTF8String, nil, 10)
                    if errno == 0 {
                        type = .Counter(counterValue)
                    }
                }
            } else if host == TokenTypeTimerString {
                type = TokenType.Timer(period: 30)
                if let periodInt = queryDictionary[kQueryPeriodKey]?.toInt() {
                    type = .Timer(period: NSTimeInterval(periodInt))
                }
            }
        }
        if type == nil { return nil } // A token type is required

        var secret = externalSecret
        if secret == nil {
            if let secretString = queryDictionary[kQuerySecretKey] {
                secret = NSData(base32String:secretString)
            }
        }
        if secret == nil { return nil } // A secret is required

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

        var algorithm = Algorithm.SHA1
        if let algorithmString = queryDictionary[kQueryAlgorithmKey] {
            if let algorithmFromURL = algorithmFromString(algorithmString) {
                algorithm = algorithmFromURL
            } else {
                return nil // Parsed an unknown algorithm string
            }
        }

        var digits = 6
        if let digitsInt = queryDictionary[kQueryDigitsKey]?.toInt() {
            digits = digitsInt
        }

        let token = Token(type:type!, secret:secret!, name:name, issuer:issuer, algorithm:algorithm, digits:digits)

        if token.isValid {
            return token
        } else {
            return nil
        }
    }
}
