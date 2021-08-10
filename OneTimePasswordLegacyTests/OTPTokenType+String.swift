//
//  OTPTokenType+String.swift
//  OneTimePasswordLegacyTests
//
//  Created by Andreas Osberghaus on 10.08.21.
//  Copyright © 2021 Matt Rubin. All rights reserved.
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
