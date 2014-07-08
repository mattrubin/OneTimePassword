//
//  Token+Serialization.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/8/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

let kOTPAuthScheme = "otpauth"
let kQueryAlgorithmKey = "algorithm"
let kQuerySecretKey = "secret"
let kQueryCounterKey = "counter"
let kQueryDigitsKey = "digits"
let kQueryPeriodKey = "period"
let kQueryIssuerKey = "issuer"

extension Token {
    class func token(URL url: NSURL, secret: NSData?) -> Token? {
        if (url.scheme != kOTPAuthScheme) { return nil }

        var queryDictionary = Dictionary<String, String>()
        if let queryItems = NSURLComponents(URL:url, resolvingAgainstBaseURL:false).queryItems {
            for object : AnyObject in queryItems {
                if let item = object as? NSURLQueryItem {
                    queryDictionary[item.name] = item.value
                }
            }
        }

        var type = TokenType.Timer
        if let typeFromURL = TokenType.fromRaw(url.host) {
            type = typeFromURL
        } else {
            return nil
        }

        var secretForToken = NSData()
        if let secret = secret {
            secretForToken = secret
        } else {
            if let secretString = queryDictionary[kQuerySecretKey] {
                secretForToken = NSData(base32String:secretString)
            }
        }

        var name = ""
        if let path = url.path {
            if path.utf16count > 1 {
                name = path.substringFromIndex(1) // Skip the leading "/"
            }
        }

        var issuer = ""
        if let issuerString = queryDictionary[kQueryIssuerKey] {
            issuer = issuerString
            // If the name is prefixed by the issuer string, trim the name
            let prefixRange = name.rangeOfString(issuerString)
            if (prefixRange.startIndex == issuer.startIndex) && (name[prefixRange.endIndex] == ":") {
                name = name.substringFromIndex(issuerString.utf16count + 1).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            }
        } else {
            // If there is no issuer string, try to extract one from the name
            let components = name.componentsSeparatedByString(":")
            if components.count > 1 {
                issuer = components[0]
                name = name.substringFromIndex(issuer.utf16count + 1).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())

            }
        }

        var algorithm = Algorithm.SHA1
        if let algorithmString = queryDictionary[kQueryAlgorithmKey] {
            if let algorithmFromURL = Algorithm.fromRaw(algorithmString) {
                algorithm = algorithmFromURL
            } else {
                return nil
            }
        }

        var digits = 6
        if let digitsInt = queryDictionary[kQueryDigitsKey]?.toInt() {
            digits = digitsInt
        }

        var period: NSTimeInterval = 30
        if let periodInt = queryDictionary[kQueryPeriodKey]?.toInt() {
            period = NSTimeInterval(periodInt)
        }

        let token = Token(type:type, secret:secretForToken, name:name, issuer:issuer, algorithm:algorithm, digits:digits, period:period)

        if let counterString = queryDictionary[kQueryCounterKey] {
            errno = 0
            let counterValue = strtoull((counterString as NSString).UTF8String, nil, 10)
            if errno == 0 {
                token.counter = counterValue
            }
        }

        if token.isValid() {
            return token
        } else {
            return nil
        }
    }

    func url() -> NSURL {
        let urlComponents = NSURLComponents()
        urlComponents.scheme = kOTPAuthScheme
        urlComponents.host = type.toRaw()
        urlComponents.path = "/" + name

        var queryItems = [
            NSURLQueryItem(name:kQueryAlgorithmKey, value:algorithm.toRaw()),
            NSURLQueryItem(name:kQueryDigitsKey, value:String(digits)),
            NSURLQueryItem(name:kQueryIssuerKey, value:issuer),
        ]

        switch type {
        case .Timer:
            queryItems += NSURLQueryItem(name:kQueryPeriodKey, value:String(Int(period)))
        case .Counter:
            queryItems += NSURLQueryItem(name:kQueryCounterKey, value:String(counter))
        }
        
        urlComponents.queryItems = queryItems
        
        return urlComponents.URL
    }
}
