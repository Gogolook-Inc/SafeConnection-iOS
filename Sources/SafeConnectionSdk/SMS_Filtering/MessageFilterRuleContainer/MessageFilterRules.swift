//
//  MessageFilterRules.swift
//  Kirin
//
//  Created by Darkes Fang on 2020/8/19.
//  Copyright © 2020 Gogolook. All rights reserved.
//

import Foundation

struct MessageFilterAction: RawRepresentable, Codable, Equatable {
    var rawValue: String
    
    static let allow: MessageFilterAction = .init(rawValue: "allow")
    static let promotion: MessageFilterAction = .init(rawValue: "promotion")
    static let transaction: MessageFilterAction = .init(rawValue: "transaction")
    static let junk: MessageFilterAction = .init(rawValue: "junk")
    static let none: MessageFilterAction = .init(rawValue: "none")
}

protocol MessageFiltering: Codable {
    static var type: RuleType { get }
    func getAction(sender: String?, messageBody: String?, matched: UnsafeMutablePointer<String?>?) -> MessageFilterAction
}

/// `KeywordAndPatternRule` uses keywords and regular expression patterns to determine if a
/// message should be filtered. A message that constains both provided keywords and patterns
/// will be filtered.
/// Please do NOT modify this struct. If you need a similar but different rule, create a new
/// type that conforms to `MessageFiltering`.
struct KeywordAndPatternRule: MessageFiltering, Codable {
    static var type: RuleType { .keywordAndPattern }
    var keywords: [String]
    var patterns: [String]
    var action: MessageFilterAction

    func getAction(sender: String?, messageBody: String?, matched: UnsafeMutablePointer<String?>? = nil) -> MessageFilterAction {
        guard let message = messageBody else {
            return .none
        }
        
        // swiftlint:disable reduce_boolean

        var matchedKeywords: [String] = []
        let containsKeyword = keywords.reduce(false) { previousResult, keyword -> Bool in
            let isMatched = message.contains(keyword)
            if isMatched { matchedKeywords.append(keyword) }
            return previousResult || isMatched
        }

        var matchedPatterns: [String] = []
        let containsPattern = patterns.reduce(false) { previousResult, pattern -> Bool in
            let isMatched = (message.range(of: pattern, options: .regularExpression) != nil)
            if isMatched { matchedPatterns.append(pattern) }
            return previousResult || isMatched
        }
        
        // swiftlint:enable reduce_boolean

        let isRuleMatched = (containsKeyword && containsPattern)
        if isRuleMatched {
            matched?.pointee = "Keywords: [\(matchedKeywords.joined(separator: ", "))], Patterns: [\(matchedPatterns.joined(separator: ", "))]"
        }
        return isRuleMatched ? action : .none
    }
}

/// `KeywordRule` uses keywords to determine if a message should be filtered. A message that
/// constains any provided keywords will be filtered.
/// Please do NOT modify this struct. If you need a similar but different rule, create a new
/// type that conforms to `MessageFiltering`.
struct KeywordRule: MessageFiltering, Codable {
    static var type: RuleType { .keyword }
    var keywords: [String]
    var action: MessageFilterAction

    func getAction(sender: String?, messageBody: String?, matched: UnsafeMutablePointer<String?>? = nil) -> MessageFilterAction {
        guard let message = messageBody else {
            return .none
        }

        // swiftlint:disable reduce_boolean
        var matchedKeywords: [String] = []
        let containsKeyword = keywords.reduce(false) { previousResult, keyword -> Bool in
            let isMatched = message.contains(keyword)
            if isMatched { matchedKeywords.append(keyword) }
            return previousResult || isMatched
        }
        
        // swiftlint:enable reduce_boolean
        
        if containsKeyword {
            matched?.pointee = "Keywords: [\(matchedKeywords.joined(separator: ", "))]"
        }
        return containsKeyword ? action : .none
    }
}
