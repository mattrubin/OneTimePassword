//
//  Token.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/7/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

@objc class Token: NSObject {
    let name: String
    let issuer: String
    let type: TokenType
    let secret: NSData
    let algorithm: Algorithm
    let digits: Int
    let period: NSTimeInterval
    var counter: UInt64 = 1

    init(type: TokenType, secret: NSData, name: String, issuer: String, algorithm: Algorithm, digits: Int, period: NSTimeInterval) {
        self.type = type
        self.secret = secret
        self.name = name
        self.issuer = issuer
        self.algorithm = algorithm
        self.digits = digits
        self.period = period
    }

    func isValid() -> Bool {
        let validType = (self.type == .Counter) || (self.type == .Timer);
        let validSecret = self.secret.length > 0;
        let validAlgorithm = (self.algorithm == .SHA1) || (self.algorithm == .SHA256) || (self.algorithm == .SHA512);
        let validDigits = (self.digits <= 8) && (self.digits >= 6);
        let validPeriod = (self.period > 0) && (self.period <= 300);

        return validType && validSecret && validAlgorithm && validDigits && validPeriod;
    }

    enum TokenType : String {
        case Counter = "hotp", Timer = "totp"
    }

    enum Algorithm : String {
        case SHA1 = "SHA1", SHA256 = "SHA256", SHA512 = "SHA512"
    }
}

let kOTPAuthScheme = "otpauth"
let kQueryAlgorithmKey = "algorithm"
let kQuerySecretKey = "secret"
let kQueryCounterKey = "counter"
let kQueryDigitsKey = "digits"
let kQueryPeriodKey = "period"
let kQueryIssuerKey = "issuer"

extension Token {
    convenience init(URL url: NSURL, secret: NSData?) {
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

        self.init(type:type, secret:secretForToken, name:name, issuer:issuer, algorithm:algorithm, digits:digits, period:period)

        if let counterString = queryDictionary[kQueryCounterKey] {
            errno = 0
            let counterValue = strtoull((counterString as NSString).UTF8String, nil, 10)
            if errno == 0 {
                self.counter = counterValue
            }
        }
    }

    func url() -> NSURL {
        let urlComponents = NSURLComponents()
        urlComponents.scheme = kOTPAuthScheme
        urlComponents.host = self.type.toRaw()
        urlComponents.path = "/" + self.name

        var queryItems = [
            NSURLQueryItem(name:kQueryAlgorithmKey, value:self.algorithm.toRaw()),
            NSURLQueryItem(name:kQueryDigitsKey, value:String(self.digits)),
            NSURLQueryItem(name:kQueryIssuerKey, value:self.issuer),
        ]

        if (self.type == .Timer) {
            queryItems += NSURLQueryItem(name:kQueryPeriodKey, value:String(format: "%.0f", self.period))
        } else if (self.type == .Counter) {
            queryItems += NSURLQueryItem(name:kQueryCounterKey, value:String(self.counter))
        }

        urlComponents.queryItems = queryItems

        return urlComponents.URL
    }
}
