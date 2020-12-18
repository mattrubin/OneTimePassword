//
//  OTPTokenType+String.swift
//  OneTimePasswordLegacyTests
//
//  Created by Andreas Osberghaus on 18.12.20.
//  Copyright © 2020 Matt Rubin. All rights reserved.
//

import Foundation

extension OTPTokenType {
    var stringValue: String {
        switch self {
        case .counter:
            return "hotp"
        case .timer:
            return "totp"
        }
    }
}
