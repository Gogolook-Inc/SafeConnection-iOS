//
//  CXPersonalIdentificationEntryProviding.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/5/27.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import Foundation

///  The protocol defines the interfaces to get identification entries for either complete mode and incremental mode for personal identification call directory extension
protocol CXPersonalIdentificationEntryProviding {
    func provideCompleteIdentificationEntries(onNextValue: (CallerInfo) -> Void) throws
    func provideIncrementalIdentificationEntries(for action: Action, onNextValue: (CallerInfo) -> Void) throws
}
