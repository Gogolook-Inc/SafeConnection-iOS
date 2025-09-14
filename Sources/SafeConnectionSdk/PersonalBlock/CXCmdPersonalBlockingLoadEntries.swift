//
//  CXCmdPersonalBlockingLoadEntries.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/5/18.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import CallKit
import Foundation

class CXCmdPersonalBlockingLoadEntries: CXCommand {
    private let context: CXCallDirectoryExtensionContext
    private let entryProvider: CXPersonalBlockingEntryProviding
    private let completionHandler: ((Bool) -> Void)?
    private let commandTypeId: CXCmdTypeIdentifier

    init(context: CXCallDirectoryExtensionContext,
         entryProvider: CXPersonalBlockingEntryProviding,
         tryLoadIncrementalEntrySet: Bool,
         completionHandler: ((Bool) -> Void)? = nil) {
        self.context = context
        self.entryProvider = entryProvider
        self.completionHandler = completionHandler
        commandTypeId = tryLoadIncrementalEntrySet ? .loadIncrementalEntrySet : .loadCompleteEntrySet
    }

    // MARK: CXCommand

    func execute() throws -> CXCmdResult {
        switch commandTypeId {
        case .loadIncrementalEntrySet:
            try tryToLoadIncrementalEntrySet()
        case .loadCompleteEntrySet:
            try loadCompleteEntrySet()
        default:
            assertionFailure("Invalid command type: \(commandTypeId.rawValue). Nothing would be in production environment")
        }
        return CXCmdResult(commandTypeId: commandTypeId, isSucceeded: true, errorMessage: nil)
    }

    private func tryToLoadIncrementalEntrySet() throws {
        if context.isIncremental {
            try loadIncrementalEntrySet()
        } else {
            //logger.info("isIncremental == false. Fallbacked to load complete entry set.")
            try loadCompleteEntrySet()
        }
    }

    private func loadCompleteEntrySet() throws {
        try entryProvider.provideCompleteBlockingEntries { [weak self] number in
            self?.context.addBlockingEntry(withNextSequentialPhoneNumber: number)
        }
    }

    private func loadIncrementalEntrySet() throws {
        // NOTE: DO NOT change the order. Removing entries should always precedes adding enntries
        try entryProvider.provideIncrementalBlockingEntries(for: .remove,
                                                            onNextValue: { [weak self] number in
                                                                self?.context.removeBlockingEntry(withPhoneNumber: number)
        })

        try entryProvider.provideIncrementalBlockingEntries(for: .add,
                                                            onNextValue: { [weak self] number in
                                                                self?.context.addBlockingEntry(withNextSequentialPhoneNumber: number)
        })
    }
}
