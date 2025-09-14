//
//  SafeConnectionSdk+SMSFiltering.swift
//  SafeConnection
//
//  Created by HanyuChen on 2025/6/27.
//

import IdentityLookup

public extension SafeConnectionSdk {
    private static var _smsFiltering: SafeConnectionSdk.SMSFiltering?
    
    var smsFiltering: SafeConnectionSdk.SMSFiltering {
        if Self._smsFiltering == nil {
            Self._smsFiltering = SafeConnectionSdk.SMSFiltering(
                urlForSecurityApplicationGroupIdentifier: OptionProvider.shared.appGroupIdentifier
            )
        }
        return Self._smsFiltering!
    }
}

public extension SafeConnectionSdk {
    struct SMSFiltering {
        private let smsAssistanthandler: SMSAssistantHandler

        init(urlForSecurityApplicationGroupIdentifier: String) {
            self.smsAssistanthandler = SMSAssistantHandler(
                urlForSecurityApplicationGroupIdentifier: urlForSecurityApplicationGroupIdentifier
            )
        }
        
        public func handle(
            _ capabilitiesQueryRequest: ILMessageFilterCapabilitiesQueryRequest,
            context: ILMessageFilterExtensionContext,
            completion: @escaping (ILMessageFilterCapabilitiesQueryResponse) -> Void
        ) {
            completion(ILMessageFilterCapabilitiesQueryResponse())
        }
        
        public func handle(
            _ queryRequest: ILMessageFilterQueryRequest,
            context: ILMessageFilterExtensionContext,
            completion: @escaping (ILMessageFilterQueryResponse) -> Void
        ) {
            let (offlineAction, offlineSubAction) = self.offlineAction(for: queryRequest)
            switch offlineAction {
            case .allow, .junk, .promotion, .transaction:
                let response = ILMessageFilterQueryResponse()
                response.action = offlineAction
                response.subAction = offlineSubAction
                completion(response)
            case .none:
                let response = ILMessageFilterQueryResponse()
                response.action = .none
                response.subAction = .none
                completion(response)
            @unknown default:
                break
            }
        }
        
        private func offlineAction(for queryRequest: ILMessageFilterQueryRequest) -> (ILMessageFilterAction, ILMessageFilterSubAction) {
            let filterAction = smsAssistanthandler.getAction(
                sender: queryRequest.sender,
                messageBody: queryRequest.messageBody
            ).converted
            return (filterAction, .none)
        }
    }
}

public extension SafeConnectionSdk.SMSFiltering {
    func enable() async throws {
        try await smsAssistanthandler.updateAutoFilterRulesIfNeeded()
    }
    
    func disable() async throws {
        try await smsAssistanthandler.removeAutoFliterRules()
    }
    
    func lastFetchDate() throws -> Date? {
        try smsAssistanthandler.lastFetchDate()
    }
}

private extension MessageFilterAction {
    var converted: ILMessageFilterAction {
        switch self {
        case .allow: return .allow
        case .junk: return .junk
        case .promotion: return .promotion
        case .transaction: return .transaction
        case .none: return .none
        default: return .none
        }
    }
}
