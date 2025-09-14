//
//  PhoneNumberInfo.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/3/18.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import CallKit
internal import RealmSwift

class PhoneNumberInfo: Object {
    @objc dynamic var e164: CXCallDirectoryPhoneNumber = 0  // e164 or short code
    @objc dynamic var label: String?
    @objc dynamic var isInSearchHistory = true
    @objc dynamic var action = Int(Delta.noAction.rawValue)       // reserved for incremental mode

    /// Usages:
    /// - To purge records when max phone number info reached the limit
    /// - To determine if the record has been updated or not
    @objc dynamic var timestamp: TimeInterval = 0 // 00:00:00 UTC on 1 January 1970.

    /// This field is used to serve UI
    @objc dynamic var geocoding: String?

    /// This field is used to serve UI
    @objc dynamic var telecom: String?

    /// This field is defined to support display rule
    @objc dynamic var type: Int = DisplayRulePhoneNumberType.noInfo.rawValue

    @objc dynamic var regionCode: String = ""     // short code need it for search API

    // primary key
    override static func primaryKey() -> String? {
        return "e164"
    }

    // indexing properties
    override static func indexedProperties() -> [String] {  // preserved for future enhancement (incremental mode)
        return ["isInSearchHistory", "action"]
    }

    func updateContent(with info: PhoneNumberInfo) {
        self.label = info.label
        self.action = info.action
        self.geocoding = info.geocoding
        self.telecom = info.telecom
        self.type = info.type
        self.regionCode = info.regionCode
    }
}
