//
//  DeltaRealmDBBlockingEntryProvider.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/5/18.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import CallKit
import Foundation
internal import RealmSwift

class DeltaRealmDBBlockingEntryProvider: CXPersonalBlockingEntryProviding {
    private let config: Realm.Configuration
    private let realmCipherKeyLength = 64   // in byte

    init(dbURL: URL, cipherKey: Data, schemaVersion: UInt64) throws {
        guard cipherKey.count == realmCipherKeyLength else {
            throw Error(with: .invalidCipherKey)
        }

        config = Realm.Configuration(fileURL: dbURL,
                                     encryptionKey: cipherKey,
                                     readOnly: false,
                                     schemaVersion: schemaVersion,    // Realm sets schemaVersion's default value to 0, if not given.
                                     objectTypes: [BlockedPhoneNumberInfo.self])
    }

    func provideCompleteBlockingEntries(onNextValue: (CXCallDirectoryPhoneNumber) -> Void) throws {
        try autoreleasepool {
            let realm = try Realm(configuration: config)
            // TODO: maybe consider to use `PersonalBlockingDBHelper` in this class to access DB?
            let predicate = NSPredicate(format: "e164 > 0 AND type = %d AND kind != %d", BlockType.phone.rawValue, Kind.delete.rawValue)
            let blockedNumbers = realm.objects(BlockedPhoneNumberInfo.self)
                .filter(predicate)
                .sorted(byKeyPath: "e164", ascending: true)
                .map { BlockedPhoneNumberInfo(value: $0) }
            realm.beginWrite()
            for numberInfo in blockedNumbers {
                autoreleasepool {
                    if let delta = Delta(rawValue: Int32(numberInfo.action)),
                        numberInfo.e164 > 0 {
                        switch delta {
                        case .add, .updateLabel:
                            onNextValue(numberInfo.e164)
                            autoreleasepool {
                                if let toBeUpdatedNumberInfo = realm.object(ofType: BlockedPhoneNumberInfo.self, forPrimaryKey: numberInfo.e164) {
                                    toBeUpdatedNumberInfo.action = Int(Delta.noAction.rawValue)
                                } else {
                                    assertionFailure("Unexpected condition")
                                }
                            }
                        case .noAction:
                            onNextValue(numberInfo.e164)
                        case .remove:
                            if let toBeDeletedNumberInfo = realm.object(ofType: BlockedPhoneNumberInfo.self, forPrimaryKey: numberInfo.e164) {
                                realm.delete(toBeDeletedNumberInfo)
                            }
                        }
                    } else {
                        // If there is a invalid delta, remove the number and log it
                        //logger.warn("Got invalid delta - rawValue: \(numberInfo.action). The record is going to be deleted")

                        if let toBeDeletedNumberInfo = realm.object(ofType: BlockedPhoneNumberInfo.self, forPrimaryKey: numberInfo.e164) {
                            realm.delete(toBeDeletedNumberInfo)
                        }
                    }
                }
            }
            try realm.commitWrite()
        }
    }

    func provideIncrementalBlockingEntries(for action: Action, onNextValue: (CXCallDirectoryPhoneNumber) -> Void) throws {
        guard let dbURL = config.fileURL, FileManager.default.fileExists(atPath: dbURL.path) else {
//            logger.debug("dbURL: \(String(describing: config.fileURL?.path))")
//            logger.warn("DB file doesn't exist")
            return
        }

        try autoreleasepool {
            let realm = try Realm(configuration: config)

            realm.beginWrite()
            let blockedNumbers = realm.objects(BlockedPhoneNumberInfo.self)
                .filter("action = %@ AND e164 > 0", action == .add ? Delta.add.rawValue : Delta.remove.rawValue)
                .sorted(byKeyPath: "e164", ascending: true)
                .map { BlockedPhoneNumberInfo(value: $0) }
            for numberInfo in blockedNumbers {
                autoreleasepool {
                    onNextValue(numberInfo.e164)
                    if let toBeUpdatedNumberInfo = realm.object(ofType: BlockedPhoneNumberInfo.self, forPrimaryKey: numberInfo.e164) {
                        toBeUpdatedNumberInfo.action = Int(Delta.noAction.rawValue)
                    } else {
                        assertionFailure("Unexpected condition")
                    }
                }
            }
            try realm.commitWrite()
        }
    }
}
