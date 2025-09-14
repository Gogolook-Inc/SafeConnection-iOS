//
//  CallerType.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/5/16.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import Foundation

struct CallerType: OptionSet {
    let rawValue: Int32

    static let `default`: CallerType = []
    static let topSpam = CallerType(rawValue: 0x1)
    static let spam = CallerType(rawValue: 0x1 << 1)
    static let card = CallerType(rawValue: 0x1 << 2)
    static let antiFraud165 = CallerType(rawValue: 0x1 << 3)
    static let biz = CallerType(rawValue: 0x1 << 4)
    static let other = CallerType(rawValue: 0x1 << 5)
    static let spoof = CallerType(rawValue: 0x1 << 6)
    static let instantBlock = CallerType(rawValue: 0x1 << 7)
    static let singaporePoliceForce = CallerType(rawValue: 0x1 << 8)
}
