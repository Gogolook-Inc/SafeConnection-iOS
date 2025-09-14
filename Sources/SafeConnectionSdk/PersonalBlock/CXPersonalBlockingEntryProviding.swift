//
//  CXPersonalBlockingEntryProviding.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/5/21.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import Foundation

import CallKit

///  The protocol defines the interfaces to get blocking entries for either complete mode and incremental mode for personal blocking call directory extension
protocol CXPersonalBlockingEntryProviding {
    func provideCompleteBlockingEntries(onNextValue: (CXCallDirectoryPhoneNumber) -> Void) throws

    func provideIncrementalBlockingEntries(for action: Action, onNextValue: (CXCallDirectoryPhoneNumber) -> Void) throws
}
