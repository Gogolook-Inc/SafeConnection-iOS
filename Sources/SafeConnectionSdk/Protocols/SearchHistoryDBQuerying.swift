//
//  SearchHistoryDBQuerying.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/6/26.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import CallKit

protocol SearchHistoryDBQuerying {
    func getPersonalIdentificationEntries() throws -> [PhoneNumberInfo]
    func getSearchHistoryEntries() throws -> [PhoneNumberInfo]
    func add(entries: [PhoneNumberInfo], updatePolicy: UpdatePolicy) throws
    func markAsRemovedFromSearchHistory(numbers: [CXCallDirectoryPhoneNumber]) throws
    func removeFromDB(numbers: [CXCallDirectoryPhoneNumber]) throws
    func update(entries: [PhoneNumberInfo]) throws
    func hasTheEntry(e164: CXCallDirectoryPhoneNumber) throws -> Bool
    func getEntryCount() throws -> Int
}
