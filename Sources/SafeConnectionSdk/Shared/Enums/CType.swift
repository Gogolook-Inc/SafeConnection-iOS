//
//  CType.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/4/1.
//  Copyright © 2019 Gogolook. All rights reserved.
//

/// the field used by Whoscall Android app. iOS always passes `unknown`
///
/// - unknown: unknown
/// - others: others (defined in Whoscall Android BlockManager.java)
/// - call: phone calls (defined in Whoscall Android BlockManager.java)
/// - sms: SMS (defined in Whoscall Android BlockManager.java)
enum CType: Int {
    case unknown = -1
    case others = 0     // Android only
    case call = 1       // Android only
    case sms = 2        // Android only
}
