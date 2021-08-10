//
//  OTPAlgorithm+String.swift
//  OneTimePasswordLegacyTests
//
//  Created by Andreas Osberghaus on 10.08.21.
//  Copyright © 2021 Matt Rubin. All rights reserved.
//

import Foundation

extension OTPAlgorithm {
     var stringValue: String {
         switch self {
         case .sha1:
             return "SHA1"
         case .sha256:
             return "SHA256"
         case .sha512:
             return "SHA512"
         }
     }
 }
