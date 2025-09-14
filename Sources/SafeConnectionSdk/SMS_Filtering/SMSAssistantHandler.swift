//
//  SMSAssistantHandler.swift
//  Kirin
//
//  Created by Darkes Fang on 2020/8/25.
//  Copyright © 2020 Gogolook. All rights reserved.
//

import Foundation

class SMSAssistantHandler {
    private let messageFilterHandler: MessageFilterHandler
    
    init(urlForSecurityApplicationGroupIdentifier: String) {
        self.messageFilterHandler = MessageFilterHandler(
            urlForSecurityApplicationGroupIdentifier: urlForSecurityApplicationGroupIdentifier
        )
    }
    
    private func merge<RuleType: RangeReplaceableCollection & Codable>(
        containerToRestore: MessageFilterRuleContainer,
        to container: MessageFilterRuleContainer,
        of type: RuleType.Type
    ) throws -> MessageFilterRuleContainer {
        var mergedContainer = container
        var rules = try JSONDecoder().decode(type, from: container.ruleData)
        let rulesToRestore = try JSONDecoder().decode(type, from: containerToRestore.ruleData)
        rules.append(contentsOf: rulesToRestore)
        mergedContainer.ruleData = try JSONEncoder().encode(rules)
        return mergedContainer
    }
}

// SafeConnection
extension SMSAssistantHandler {
    func updateAutoFilterRulesIfNeeded() async throws {
        let source = MessageFilterHandler.Source.auto
        let lastFetchDate = try messageFilterHandler.lastFetchDate(for: source)
        if lastFetchDate == nil || Date().over7Days(of: lastFetchDate!) {
            let ruleContainers = try await fetchSMSFilterRulesFromServer()
            messageFilterHandler.updateRules(ruleContainers, to: source)
        }
    }
    
    func removeAutoFliterRules() async throws {
        try messageFilterHandler.removeRules(from: .auto)
    }
    
    private func fetchSMSFilterRulesFromServer() async throws -> [MessageFilterRuleContainer] {
        try await SMSFilterService().getCDNURL(
            region: "JP",
            accessToken: SharedLocalStorage.shared.accessToken,
            userAgent: SharedLocalStorage.shared.userAgent
        )
    }
    
    func getAction(sender: String?, messageBody: String?) -> MessageFilterAction {
        return messageFilterHandler.getAction(
            sender: sender,
            messageBody: messageBody
        )
    }
    
    func lastFetchDate() throws -> Date? {
        try messageFilterHandler.lastFetchDate(for: .auto)
    }
}
