//
//  PersonalBlockingDBQuerying.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/6/26.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import CallKit

protocol PersonalBlockingDBQuerying {
    func getEntries() throws -> [BlockedPhoneNumberInfo]
    func getExtensionEntries() throws -> [BlockedPhoneNumberInfo]
    func getUIEntries() throws -> [BlockedPhoneNumberInfo]
    func add(entries: [BlockedPhoneNumberInfo], updatePolicy: UpdatePolicy, checkLimit: Bool) throws
    func removeFromDB(numbers: [CXCallDirectoryPhoneNumber]) throws
    func removeAllBlockedPhoneNumberInfo() throws
    func update(syncTime: TimeInterval?) throws
    func update(entries: [BlockedPhoneNumberInfo]) throws
    func getSyncTime() throws -> TimeInterval?
    func getEntryCount() throws -> Int
}
