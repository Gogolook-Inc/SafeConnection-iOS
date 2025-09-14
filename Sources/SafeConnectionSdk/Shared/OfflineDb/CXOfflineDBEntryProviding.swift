//
//  CXOfflineDBEntryProviding.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/5/14.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import CallKit

/// The protocol defines the interfaces to get identification entries and blocking entries for either complete mode and incremental mode for offline db call directory extension
public protocol CXOfflineDBEntryProviding {
    func provideCompleteIdentificationEntries(onNextValue: (CallerInfo) -> Void) throws
    func provideCompleteBlockingEntries(onNextValue: (CXCallDirectoryPhoneNumber) -> Void) throws
}
