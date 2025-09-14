//
//  CXCmdPersonalIdentificationLoadEntries.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/5/27.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import CallKit
import Foundation

class CXCmdPersonalIdentificationLoadEntries: CXCommand {
    private let context: CXCallDirectoryExtensionContext
    private let entryProvider: CXPersonalIdentificationEntryProviding
    private let completionHandler: ((Bool) -> Void)?
    private let commandTypeId: CXCmdTypeIdentifier

    init(context: CXCallDirectoryExtensionContext,
         entryProvider: CXPersonalIdentificationEntryProviding,
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
            //logger.info("isIncremental is false. Loading complete entry set instead")
            try loadCompleteEntrySet()
        }
    }

    private func loadCompleteEntrySet() throws {
        try entryProvider.provideCompleteIdentificationEntries { [weak self] callerInfo in
            self?.context.addIdentificationEntry(withNextSequentialPhoneNumber: callerInfo.number, label: callerInfo.name)
        }
    }

    private func loadIncrementalEntrySet() throws {
        // NOTE: DO NOT change the order. Removing entries should always precedes adding entries
        try entryProvider.provideIncrementalIdentificationEntries(for: .remove, onNextValue: { [weak self] callerInfo in
            self?.context.removeIdentificationEntry(withPhoneNumber: callerInfo.number)
        })
        try entryProvider.provideIncrementalIdentificationEntries(for: .add, onNextValue: { [weak self] callerInfo in
            self?.context.addIdentificationEntry(
                withNextSequentialPhoneNumber: callerInfo.number,
                label: callerInfo.name
            )
        })
    }
}
