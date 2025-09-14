//
//  MessageFilterHandler.swift
//  Kirin
//
//  Created by Darkes Fang on 2020/8/17.
//  Copyright © 2020 Gogolook. All rights reserved.
//

import Foundation
//import KirinMacros

class MessageFilterHandler {
    private let urlForSecurityApplicationGroupIdentifier: String
    private let fileHelper = FileHelper()
    enum Source: String {
        case auto
//        case custom
//        case mlmodel
    }

    init(urlForSecurityApplicationGroupIdentifier: String) {
        self.urlForSecurityApplicationGroupIdentifier = urlForSecurityApplicationGroupIdentifier
    }

    func updateRules(_ rules: [MessageFilterRuleContainer], to source: Source) {
        do {
            for rule in rules {
                // Validate rules
                try decodeRules(data: rule.ruleData, by: rule.type)
            }

            var fileURL = getFileURL(for: source)
            try fileHelper.save(value: rules, to: fileURL)
            
//            if source == .custom {
            fileURL.excludeFromBackup()
//            }
            var timestampFileURL = getLastModifiedDateFileURL(for: source)
            try fileHelper.save(value: Date(), to: timestampFileURL)
            timestampFileURL.excludeFromBackup()
        } catch {
//            #log(.error, "Failed to update rules: \(error)")
            assertionFailure("Failed to update rules \(error)")
        }
    }

    /// Get message filter rule containers from the given source.
    /// - Parameter source: The source to get the rules from.
    /// - Returns: Returns `nil` if errors occur, otherwise returns an array of `MessageFilterRuleContainer`. The array is empty if there's no saved data.
    private func getContainers(from source: Source) -> [MessageFilterRuleContainer]? {
        getContainers(from: getFileURL(for: source))
    }

    /// Get message filter rule containers from the given URL.
    /// - Parameter url: The url to get the rules from.
    /// - Returns: Returns `nil` if errors occur, otherwise returns an array of `MessageFilterRuleContainer`. The array is empty if there's no saved data.
    private func getContainers(from url: URL) -> [MessageFilterRuleContainer]? {
        do {
            return try fileHelper.get(type: Array<MessageFilterRuleContainer>.self, from: url)
        } catch CocoaError.fileReadNoSuchFile {
            return []
        } catch {
//            #log(.error, "Failed to update rule containers: \(error)")
            return nil
        }
    }

    /// Get all saved message filter rules from the given source.
    /// - Parameter source: The source to get the rules from.
    /// - Returns: Returns `nil` if errors occur, otherwise returns an array of `MessageFiltering`. The array is empty if there's no saved data.
    private func getRules(from source: Source) -> [MessageFiltering]? {
        do {
            let rulesArray = try fileHelper.get(type: Array<MessageFilterRuleContainer>.self, from: getFileURL(for: source))
            return try rulesArray.flatMap { try $0.getRules() }
        } catch CocoaError.fileReadNoSuchFile {
            return []
        } catch {
//            #log(.error, "Failed to get rules: \(error)")
            return nil
        }
    }

    /// Get specific type of message filter rules from the given source.
    /// - Parameter type: Returned rule type.
    /// - Parameter source: The source to get the rules from.
    /// - Returns: Returns `nil` if errors occur, otherwise returns an array of given type. The array is empty if there's no saved data.
    private func getRules<T: MessageFiltering>(of type: T.Type, from source: Source) -> [T]? {
        do {
            let rulesArray = try fileHelper.get(type: Array<MessageFilterRuleContainer>.self, from: getFileURL(for: source))
            return try rulesArray.flatMap { try $0.getRules(of: type) }
        } catch CocoaError.fileReadNoSuchFile {
            return []
        } catch {
//            #log(.error, "Failed to get rules: \(error)")
            return nil
        }
    }

    func removeRules(from source: Source) throws {
//        do {
        try fileHelper.remove(from: getFileURL(for: source))
        try fileHelper.remove(from: getLastModifiedDateFileURL(for: source))
//        } catch {
//            #log(.error, "Failed to remove rule file: \(error)")
//        }
    }

    private func getAction(from source: Source, sender: String?, messageBody: String?, matchedRule: UnsafeMutablePointer<String?>? = nil) -> MessageFilterAction {
        switch source {
//        case .mlmodel:
//            guard let classifier = classifier else {
//                return .none
//            }
//            do {
//                let result = try classifier.inferResult(for: sender ?? "", messageBody: messageBody ?? "")
//
//                if result.count == 2 {
//                    matchedRule?.pointee = "\(result[0]), \(result[1])"
//                    return result[0] > result[1] ? .allow : .junk
//                } else if result.count == 4 {
//                    matchedRule?.pointee = "\(result[0]), \(result[1]), \(result[2]), \(result[3])"
//                    var indexOfMax = 0
//                    var unpredictable = false
//                    for (index, item) in result.enumerated() {
//                        if item > result[indexOfMax] {
//                            indexOfMax = index
//                            unpredictable = false
//                        } else if index != indexOfMax && item == result[indexOfMax] {
//                            unpredictable = true
//                        }
//                    }
//                    return unpredictable ? .none : [.allow, .junk, .transaction, .promotion][indexOfMax]
//                } else {
//                    return .none
//                }
//            } catch {
//                return .none
//            }
        default:
            guard let rules = getRules(from: source) else {
                return .none
            }

            let action = rules.reduce(MessageFilterAction.none) { previousResult, rule -> MessageFilterAction in
                var ruleText: String?
                let action = rule.getAction(sender: sender, messageBody: messageBody, matched: &ruleText)

                func check(_ theAction: MessageFilterAction) -> MessageFilterAction? {
                    if previousResult == theAction || action == theAction {
                        if action == theAction {
                            matchedRule?.pointee = ruleText
                        }
                        return theAction
                    }
                    return nil
                }
                
                return check(.allow) ?? check(.junk) ?? check(.promotion) ?? check(.transaction) ?? .none
            }

            return action
        }
    }
    
    func getAction(
        sender: String?,
        messageBody: String?,
        bySource source: UnsafeMutablePointer<Source?>? = nil,
        byRule rule: UnsafeMutablePointer<String?>? = nil
    ) -> MessageFilterAction {

        var inferRule: String?
//        let customAction = getAction(from: .custom, sender: sender, messageBody: messageBody, matchedRule: &inferRule)
//
//        if customAction != .none {
//            rule?.pointee = inferRule
//            source?.pointee = .custom
//            return customAction
//        }

        let autoAction = getAction(from: .auto, sender: sender, messageBody: messageBody, matchedRule: &inferRule)
        if autoAction != .none {
            rule?.pointee = inferRule
            source?.pointee = .auto
            return autoAction
        }

//        let mlAction = getAction(from: .mlmodel, sender: sender, messageBody: messageBody, matchedRule: &inferRule)
//        if mlAction != .none {
//            rule?.pointee = inferRule
//            source?.pointee = .mlmodel
//            return mlAction
//        }

        return .none
    }

    // TODO: Design a error throw
    private func getFileURL(for source: Source) -> URL {
        switch source {
        case .auto:
            guard
                let url = FileManager.default
                    .containerURL(forSecurityApplicationGroupIdentifier: urlForSecurityApplicationGroupIdentifier)?
                    .appendingPathComponent("message_filter_auto_rules.json")
            else {
                fatalError("")
            }
            return url
//            return appProperties.messageFilterAutoRuleFileURL
//        case .custom:
//            return appProperties.messageFilterCustomRuleFileURL
//        case .mlmodel:
//            return appProperties.messageFilterMLModelFileURL
        }
    }
    
    private func getLastModifiedDateFileURL(for source: Source) -> URL {
        switch source {
        case .auto:
            guard
                let url = FileManager.default
                    .containerURL(forSecurityApplicationGroupIdentifier: urlForSecurityApplicationGroupIdentifier)?
                    .appendingPathComponent("message_filter_auto_rules_timestamp.json")
            else {
                fatalError("Failed to get container URL for security application group: \(urlForSecurityApplicationGroupIdentifier)")
            }
            return url
        }
    }

    @discardableResult
    private func decodeRules(data: Data, by type: RuleType) throws -> [MessageFiltering] {
        switch type {
        case .keyword:
            return try JSONDecoder().decode(Array<KeywordRule>.self, from: data)
        case .keywordAndPattern:
            return try JSONDecoder().decode(Array<KeywordAndPatternRule>.self, from: data)
        }
    }
}

extension MessageFilterHandler {
    func lastFetchDate(for source: Source) throws -> Date? {
        let fileURL = getLastModifiedDateFileURL(for: source)
        guard fileHelper.fileExists(url: fileURL) else { return nil }
        let date = try fileHelper.get(type: Date.self, from: fileURL)
        return date
    }
}
