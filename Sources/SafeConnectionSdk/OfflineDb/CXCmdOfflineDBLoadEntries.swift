//
//  CXCmdOfflineDBLoadEntries.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/5/17.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import CallKit
import Foundation

public class CXCmdOfflineDBLoadEntries: CXCommand {
    private let context: CXCallDirectoryExtensionContext
    private let entryProvider: CXOfflineDBEntryProviding
//    private let diffId: Int
    private let blockTopSpamNumbers: Bool
    private let commandTypeId: CXCmdTypeIdentifier
    private let completionHandler: ((Bool) -> Void)?

    /// Instantiate a complete load-entry command
    ///
    /// - Parameters:
    ///   - context: the context of the corresponding call directory extension
    ///   - diffId: the difference of (new DB version number - current DB version number) / 2
    ///   (NOTE: DB version is stepped by 2, therefore we have to divide the difference by 2).
    ///    `0` denotes complete mode
    ///   - blockTopSpamNumbers: whether blocks top spam numbers in offline DB
    ///   - completionHandler: the completion handler for `context`'s `completeRequest` method
    public init(context: CXCallDirectoryExtensionContext,
                entryProvider: CXOfflineDBEntryProviding,
//                diffId: Int,
                blockTopSpamNumbers: Bool,
                completionHandler: ((Bool) -> Void)? = nil) {
        self.context = context
        self.completionHandler = completionHandler
        self.entryProvider = entryProvider
//        self.diffId = diffId
        self.blockTopSpamNumbers = blockTopSpamNumbers
        commandTypeId = .loadCompleteEntrySet
    }

    public func execute() throws -> CXCmdResult {
//        if diffId <= OfflineDBCallDirectoryHandler.completeEntrySetDiffId {    // load complete entry set
//            logger.warn("Invalid diffId: \(diffId). Load complete entry set instead")
//            try loadCompleteEntrySet()
//        } else {
//            try tryToLoadIncrementalEntrySet()
//        }
        try loadCompleteEntrySet()
        return CXCmdResult(commandTypeId: commandTypeId, isSucceeded: true, errorMessage: nil)
    }

    private func tryToLoadIncrementalEntrySet() throws {
//        if context.isIncremental {
//            try loadIncrementalEntrySet()
//        } else {    // if call directory extension can't load incrementally, fallback to complete entry set
//            //logger.info("isIncremental == false. Fallbacked to load complete entry set.")
//            try loadCompleteEntrySet()
//        }
        try loadCompleteEntrySet()
    }

//    private func loadIncrementalEntrySet() throws {
//        var numberOfIdentificationEntriesRemoved = 0
//        var numberOfBlockingEntriesRemoved = 0
//        var numberOfIdentificationEntriesAdded = 0
//        var numberOfBlockingEntriesAdded = 0
//
//        try entryProvider.provideIncrementalIdentificationEntries(diffId: diffId, for: .remove, onNextValue: { [weak self] callerInfo in
//            self?.context.removeIdentificationEntry(withPhoneNumber: callerInfo.number)
//            numberOfIdentificationEntriesRemoved += 1
//        })
//
//        try entryProvider.provideIncrementalBlockingEntries(diffId: diffId, for: .remove, onNextValue: { [weak self] number in
//                self?.context.removeBlockingEntry(withPhoneNumber: number)
//                numberOfBlockingEntriesRemoved += 1
//        })
//
//        try entryProvider.provideIncrementalIdentificationEntries(diffId: diffId, for: .add, onNextValue: { [weak self] callerInfo in
//            self?.context.addIdentificationEntry(withNextSequentialPhoneNumber: callerInfo.number, label: callerInfo.name)
//            numberOfIdentificationEntriesAdded += 1
//        })
//
//        if blockTopSpamNumbers {
//            try entryProvider.provideIncrementalBlockingEntries(diffId: diffId, for: .add, onNextValue: { [weak self] number in
//                self?.context.addBlockingEntry(withNextSequentialPhoneNumber: number)
//                numberOfBlockingEntriesAdded += 1
//            })
//        }
//
//        // swiftlint:disable line_length
//        //logger.info("#-i-r: \(numberOfIdentificationEntriesRemoved), #-b-r: \(numberOfBlockingEntriesRemoved), #-i-a: \(numberOfIdentificationEntriesAdded), #-b-a: \(numberOfBlockingEntriesAdded)")
//        // swiftlint:enable line_length
//    }

    private func loadCompleteEntrySet() throws {
        try entryProvider.provideCompleteIdentificationEntries { [weak self] callerInfo in
            self?.context.addIdentificationEntry(withNextSequentialPhoneNumber: callerInfo.number, label: callerInfo.name)
        }

        if blockTopSpamNumbers {
            try entryProvider.provideCompleteBlockingEntries { [weak self] number in
                self?.context.addBlockingEntry(withNextSequentialPhoneNumber: number)
            }
        }
    }
}
