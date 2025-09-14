//
//  BlockedPhoneNumberInfo.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/3/28.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import CallKit
internal import RealmSwift

class BlockedPhoneNumberInfo: Object, Codable {
    // As this field is used for sorting and passed to Call directory extension to block numbers, it's defined  to be CXCallDirectoryPhoneNumber
    @objc dynamic var e164: CXCallDirectoryPhoneNumber = 0
    // this number is what the user ACTUALLY given through the input. Confirmed with Carlos, Android takes only digits.
    @objc dynamic var number: String = ""
    @objc dynamic var type: Int = BlockType.phone.rawValue
    @objc dynamic var kind: Int = Kind.phone.rawValue
    @objc dynamic var reason: String = ""
    @objc dynamic var createTime: TimeInterval = 0 // 00:00:00 UTC on 1 January 1970
    @objc dynamic var updateTime: TimeInterval = 0 // 00:00:00 UTC on 1 January 1970
    @objc dynamic var clientType: Int = CType.unknown.rawValue
    @objc dynamic var customNumCategory: Int = CCat.unknown.rawValue
    @objc dynamic var prefCategoryBlock: String?
    @objc dynamic var regionCode: String = ""
    let prefBlockOtherDDD = RealmProperty<Bool?>()

    //////////////////////////
    // For incremental mode //
    //////////////////////////
    // The following properties takes no place during encoding and decoding, as
    // they are not part of sync data
    @objc dynamic var action = Int(Delta.noAction.rawValue)       // reserved for incremental mode

    override static func primaryKey() -> String? {
        return "e164"
    }

    // indexing properties
    override static func indexedProperties() -> [String] {  // preserved for future enhancement (incremental mode)
        return ["action"]
    }

    // MARK: Codable
    private enum CodingKeys: String, CodingKey {
        case value = "value",
        key = "key",
        ext = "ext",
        updateTime = "update_time"
    }

    // MARK: Private structure
    private struct Ext: Codable {
        let callType: Int
        let customNumCategory: Int

        private enum CodingKeys: String, CodingKey {
            case cType = "_ctype",
            ccat = "_ccat"
        }

        init(cType: Int,
             cCat: Int) {
            self.callType = cType
            self.customNumCategory = cCat
        }

        // MARK: Codable

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(callType, forKey: .cType)
            try container.encode(customNumCategory, forKey: .ccat)
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            callType = try container.decode(Int.self, forKey: .cType)
            customNumCategory = try container.decode(Int.self, forKey: .ccat)
        }
    }

    private struct Key: Codable {
        let type: Int
        let e164: String

        private enum CodingKeys: String, CodingKey {
            case type = "_type",
            e164 = "_e164"
        }

        init(type: Int,
             e164: String) {
            self.type = type
            self.e164 = e164
        }

        // MARK: Codable

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(type, forKey: .type)
            try container.encode(e164, forKey: .e164)
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            type = try container.decode(Int.self, forKey: .type)
            e164 = try container.decode(String.self, forKey: .e164)
        }
    }

    private struct Value: Codable {
        var type: Int
        var updateTime: TimeInterval
        var e164: CXCallDirectoryPhoneNumber
        var kind: Int
        var createTime: TimeInterval
        var reason: String
        var number: String
        var prefCategoryBlock: String?
        var prefBlockOtherDDD: Bool?

        private enum CodingKeys: String, CodingKey {
            case type = "_type",
            updateTime = "_updatetime",
            e164 = "_e164",
            kind = "_kind",
            createTime = "_createtime",
            reason = "_reason",
            number = "_number",
            prefCategoryBlock = "pref_category_block",
            prefBlockOtherDDD = "pref_block_other_ddd",
            isDeleted = "_deleted"
        }

        init(type: Int,
             updateTime: TimeInterval,
             e164: CXCallDirectoryPhoneNumber,
             kind: Int,
             createTime: TimeInterval,
             reason: String,
             number: String,
             prefCategoryBlock: String? = nil,
             prefBlockOtherDDD: Bool? = nil) {
            self.type = type
            self.updateTime = updateTime
            self.e164 = e164
            self.kind = kind
            self.createTime = createTime
            self.reason = reason
            self.number = number
            self.prefCategoryBlock = prefCategoryBlock
            self.prefBlockOtherDDD = prefBlockOtherDDD
        }

        // MARK: Codable

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(type, forKey: .type)
            try container.encode(updateTime.floorToMillisecond(), forKey: .updateTime)

            let phoneNumberUtil = PhoneNumberUtil(number: e164)
            try container.encode(phoneNumberUtil.e164 ?? "\(e164)", forKey: .e164)

            try container.encode(kind, forKey: .kind)
            try container.encode(createTime.floorToMillisecond(), forKey: .createTime) // in msec
            try container.encode(reason, forKey: .reason)
            try container.encode(number, forKey: .number)

            // Optionals
            try container.encodeIfPresent(prefCategoryBlock, forKey: .prefCategoryBlock)
            try container.encodeIfPresent(prefBlockOtherDDD, forKey: .prefBlockOtherDDD)

            // Currently, Android app set _kind = -1 as deleted
            // And will be changed to use _deleted = 1 in the future
            try container.encode(kind < 0 ? 1 : 0, forKey: .isDeleted)
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            do {
                type = try container.decode(Int.self, forKey: .type)

                let e164String = try container.decode(String.self, forKey: .e164)
                e164 = CXCallDirectoryPhoneNumber(e164String) ?? 0 // Assign zero if number is invalid

                updateTime = try container.decode(Int64.self, forKey: .updateTime).fromMilliSecondToTimeInterval()
                createTime = try container.decode(Int64.self, forKey: .createTime).fromMilliSecondToTimeInterval()
                kind = try container.decode(Int.self, forKey: .kind)
            } catch {
                // Set default value to avoid parsing error
                // And this data will be ignored before write into db in SyncHandler
                type = BlockType.unknown.rawValue
                e164 = 0
                updateTime = 0.0
                createTime = 0.0
                kind = Kind.delete.rawValue
            }
            number = (try? container.decodeIfPresent(String.self, forKey: .number)) ?? ""
            reason = (try? container.decodeIfPresent(String.self, forKey: .reason)) ?? ""

            // Optionals
            prefCategoryBlock = try container.decodeIfPresent(String.self, forKey: .prefCategoryBlock)
            prefBlockOtherDDD = try container.decodeIfPresent(Bool.self, forKey: .prefBlockOtherDDD)
        }
    }

    // MARK: Codable

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        let phoneNumberUtil = PhoneNumberUtil(number: e164)

        try container.encode(updateTime.floorToSecond(), forKey: .updateTime)
        let keyStruct = Key(type: type, e164: phoneNumberUtil.e164 ?? "\(e164)")
        try container.encode(keyStruct, forKey: .key)

        let valueStruct = Value(type: type,
                                updateTime: updateTime,
                                e164: e164,
                                kind: kind,
                                createTime: createTime,
                                reason: reason,
                                number: number,
                                prefCategoryBlock: prefCategoryBlock,
                                prefBlockOtherDDD: prefBlockOtherDDD.value)
        try container.encode(valueStruct, forKey: .value)
        let extStruct = Ext(cType: clientType, cCat: customNumCategory)
        try container.encode(extStruct, forKey: .ext)
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let value = try container.decode(Value.self, forKey: .value)
        updateTime = value.updateTime
        e164 = value.e164
        type = value.type
        createTime = value.createTime
        updateTime = value.updateTime
        kind = value.kind
        number = value.number
        reason = value.reason

        // Optionals
        prefCategoryBlock = value.prefCategoryBlock
        prefBlockOtherDDD.value = value.prefBlockOtherDDD
    }
}
