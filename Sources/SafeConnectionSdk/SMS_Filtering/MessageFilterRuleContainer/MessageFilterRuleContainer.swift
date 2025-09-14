//
//  MessageFilterRuleContainer.swift
//  Kirin
//
//  Created by Darkes Fang on 2020/8/17.
//  Copyright © 2020 Gogolook. All rights reserved.
//

import Foundation

enum RuleType: String, Codable {
    case keyword = "keyword"
    case keywordAndPattern = "keyword_and_pattern"
}

/// `MessageFilterRuleContainer` is the container for rules of an assigned rule type.
/// The rules are declared as Data to hide
struct MessageFilterRuleContainer: Codable {
    var type: RuleType
    var ruleData: Data
    var isAvailable = true

    enum CodingKeys: String, CodingKey {
        case type = "type"
        case ruleData = "rule_data"
        case isAvailable = "is_available"
    }

    init(type: RuleType, ruleData: Data, isAvailable: Bool = true) {
        self.type = type
        self.ruleData = ruleData
        self.isAvailable = isAvailable
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(RuleType.self, forKey: .type)
        self.ruleData = try container.decode(Data.self, forKey: .ruleData)
        if let isAvailable = try container.decodeIfPresent(Bool.self, forKey: .isAvailable) {
            self.isAvailable = isAvailable
        }
    }

    static func makeContainers(from jsonObject: Any) throws -> [MessageFilterRuleContainer] {
        guard let array = jsonObject as? [[String: Any]], JSONSerialization.isValidJSONObject(array) else {
            throw Error(with: .invalidFormat)
        }

        var result = [MessageFilterRuleContainer]()
        for obj in array {
            guard let typeString = obj[CodingKeys.type.rawValue] as? String,
                let type = RuleType(rawValue: typeString) else {
                continue
            }

            guard let ruleDataJSON = obj[CodingKeys.ruleData.rawValue] else {
//                #log(.error, "Missing rule data in the JSON object")
//                #log(.debug, "JSON: \(obj)")
                continue
            }

            do {
                let data = try JSONSerialization.data(withJSONObject: ruleDataJSON)
                result.append(MessageFilterRuleContainer(type: type, ruleData: data))
            } catch {
//                #log(.error, "Failed to serialize JSON object to data: \(error)")
            }
        }

        return result
    }

    static func makeContainer(with keywords: [KeywordRule], isAvailable: Bool = true) -> MessageFilterRuleContainer? {
        do {
            return try MessageFilterRuleContainer(type: .keyword, ruleData: JSONEncoder().encode(keywords), isAvailable: isAvailable)
        } catch {
//            #log(.error, "Failed to make rule container: \(error)")
            return nil
        }
    }

    func getRules() throws -> [MessageFiltering] {
        guard isAvailable else {
            return []
        }

        switch type {
        case .keyword:
            return try JSONDecoder().decode(Array<KeywordRule>.self, from: ruleData)
        case .keywordAndPattern:
            return try JSONDecoder().decode(Array<KeywordAndPatternRule>.self, from: ruleData)
        }
    }

    func getRules<T: MessageFiltering>(of type: T.Type) throws -> [T] {
        guard isAvailable else {
            return []
        }

        return try JSONDecoder().decode(Array<T>.self, from: ruleData)
    }
}
