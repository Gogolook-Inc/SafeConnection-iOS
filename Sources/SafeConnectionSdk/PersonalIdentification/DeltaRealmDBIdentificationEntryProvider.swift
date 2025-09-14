//
//  DeltaRealmDBIdentificationEntryProvider.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/5/27.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import CallKit
import Foundation
internal import RealmSwift

class DeltaRealmDBIdentificationEntryProvider: CXPersonalIdentificationEntryProviding {
    private let config: Realm.Configuration

    init(dbURL: URL, cipherKey: Data, schemaVersion: UInt64) {
        config = Realm.Configuration(fileURL: dbURL,
                                     encryptionKey: cipherKey,
                                     readOnly: false,
                                     schemaVersion: schemaVersion,
                                     objectTypes: [PhoneNumberInfo.self])
    }

    func provideCompleteIdentificationEntries(onNextValue: (CallerInfo) -> Void) throws {
        try autoreleasepool {
            let realm = try Realm(configuration: config)
            realm.beginWrite()
            let numberInfoArray = realm.objects(PhoneNumberInfo.self)
                .filter("label != nil AND label != '' AND e164 > 0")
                .sorted(byKeyPath: "e164", ascending: true)
                .map { PhoneNumberInfo(value: $0) } // to keep unmanaged objects instead of the managed ones

            // As numberInfoArray is filtered with label != nil, it should be safe to force unwrapp the field `label`
            for numberInfo in numberInfoArray {
                autoreleasepool {
                    if let delta = Delta(rawValue: Int32(numberInfo.action)) {
                        let type = { () -> DisplayRulePhoneNumberType in
                            guard let result = DisplayRulePhoneNumberType(rawValue: numberInfo.type) else {
                                //logger.warn("Invalid raw value for display rule phone number type (value: \(numberInfo.type)")
                                return DisplayRulePhoneNumberType.noInfo
                            }
                            return result
                        }()

                        switch delta {
                        case .add, .updateLabel:
                            let callerInfo = CallerInfo(number: numberInfo.e164,
                                                        name: getLabelPrefixBy(type: type) + numberInfo.label!)
                            onNextValue(callerInfo)
                            autoreleasepool {
                                if let toBeUpdatedNumberInfo = realm.object(ofType: PhoneNumberInfo.self, forPrimaryKey: numberInfo.e164) {
                                    toBeUpdatedNumberInfo.action = Int(Delta.noAction.rawValue)
                                } else {
                                    assertionFailure("Unexpected condition")
                                }
                            }
                        case .noAction:

                            let callerInfo = CallerInfo(number: numberInfo.e164,
                                                        name: getLabelPrefixBy(type: type) + numberInfo.label!)
                            onNextValue(callerInfo)
                        case .remove:
                            if let toBeDeletedNumberInfo = realm.object(ofType: PhoneNumberInfo.self, forPrimaryKey: numberInfo.e164) {
                                realm.delete(toBeDeletedNumberInfo)
                            }
                        }
                    } else {
                        // If there is a invalid delta, remove the number and log it
                        //logger.warn("Got invalid delta - rawValue: \(numberInfo.action). The record is going to be deleted")
                        if let toBeDeletedNumberInfo = realm.object(ofType: PhoneNumberInfo.self, forPrimaryKey: numberInfo.e164) {
                            realm.delete(toBeDeletedNumberInfo)
                        } else {
                            assertionFailure("Unexpected condition")
                        }
                    }
                }
            }
            try realm.commitWrite()
        }
    }

    func provideIncrementalIdentificationEntries(for action: Action, onNextValue: (CallerInfo) -> Void) throws {
        try autoreleasepool {
            let realm = try Realm(configuration: config)

            realm.beginWrite()
            let numberInfoArray = realm.objects(PhoneNumberInfo.self)
                .filter("action = %@ AND label != nil AND label != '' AND e164 > 0", action == .add ? Delta.add.rawValue : Delta.remove.rawValue)
                .sorted(byKeyPath: "e164", ascending: true)
                .map { PhoneNumberInfo(value: $0) } // to keep unmanaged objects instead of the managed ones

            // As numberInfoArray is filtered with label != nil, it should be safe to force unwrapp the field `label`
            for numberInfo in numberInfoArray {
                autoreleasepool {
                    let type = { () -> DisplayRulePhoneNumberType in
                        guard let result = DisplayRulePhoneNumberType(rawValue: numberInfo.type) else {
                            //logger.warn("Invalid raw value for display rule phone number type (value: \(numberInfo.type)")
                            return DisplayRulePhoneNumberType.noInfo
                        }
                        return result
                    }()

                    let callerInfo = CallerInfo(number: numberInfo.e164,
                                                name: getLabelPrefixBy(type: type) + numberInfo.label!)
                    onNextValue(callerInfo)
                    autoreleasepool {
                        if let toBeUpdatedNumberInfo = realm.object(ofType: PhoneNumberInfo.self, forPrimaryKey: numberInfo.e164) {
                            toBeUpdatedNumberInfo.action = Int(Delta.noAction.rawValue)
                        } else {
                            assertionFailure("Unexpected condition")
                        }
                    }
                }
            }
            try realm.commitWrite()
        }
    }

    private func getLabelPrefixBy(type: DisplayRulePhoneNumberType) -> String {
        switch type {
        case .spam, .singaporePoliceForce:
            return "⚠️"
        case .whoscallNumber:
            return "✅"
        default:
            return ""
        }
    }
}
