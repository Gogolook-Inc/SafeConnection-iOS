//
//  SafeConnectionSdk+SafariURLScanner.swift
//  Example
//
//  Created by HanyuChen on 2025/7/24.
//

import Foundation
import os
import SafariServices
import UserNotifications

public extension SafeConnectionSdk {
    private static var _safariURLScanner: SafeConnectionSdk.SafariURLScanner?
    
    var safariURLScanner: SafeConnectionSdk.SafariURLScanner {
        if Self._safariURLScanner == nil {
            Self._safariURLScanner = SafeConnectionSdk.SafariURLScanner()
        }
        return Self._safariURLScanner!
    }
}

public extension SafeConnectionSdk {
    struct SafariURLScanner {
        private let logger: Logger = {
            let subsystem = Bundle(for: SafeConnectionSdk.self).bundleIdentifier!
            let logger = Logger(subsystem: subsystem, category: "SafariExtension")
            return logger
        }()
        
        struct Message {
            let action: WebAction
            let title: String
            let url: URL
            
            struct WebAction: RawRepresentable, Equatable {
                let rawValue: String
                static let urlScan = Self(rawValue: "urlScan")
            }
        }
        
        public func beginRequest(with context: NSExtensionContext) {
            logger.debug("\(#fileID), \(#function), context: \(context, privacy: .public)")
            guard let message = context.convertToMessage() else {
                logger.debug("\(#fileID), \(#function), context convertToMessage failed")
                return context.completeRequest(returningItems: nil)
            }
            guard message.action == .urlScan else {
                logger.debug("\(#fileID), \(#function), message.action != .urlScan, action:\(message.action.rawValue), title:\(message.title), url:\(message.url)")
                return context.completeRequest(returningItems: nil)
            }
            logger.debug("\(#fileID), \(#function), .urlScan")
            Task {
                do {
                    try await urlScanProcess(url: message.url)
                } catch {
                    logger.debug("\(#fileID), \(#function), error: \(error)")
                }
                context.completeRequest(returningItems: nil)
            }
        }
        
        public func showSafariURLScanActivatedNotification() {
            let notificationCenter = UNUserNotificationCenter.current()
            let content = UNMutableNotificationContent()
            content.title = "🔎 Safari Auto Web Checker is running"
            content.body = "If a suspicious website is found, you will be alerted via notifications."
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            let request = UNNotificationRequest(identifier: "SafariURLScanActivated", content: content, trigger: trigger)
            notificationCenter.add(request, withCompletionHandler: nil)
        }
        
        private func urlScanProcess(url: URL) async throws {
            let level = try await checkConfidenceLevel(url: url)
            if level.isDangerous {
                try await pushLocalNotification(url: url)
            }
        }
        
        public func checkConfidenceLevel(url: URL) async throws -> ConfidenceLevel {
            // TODO:
            // Fetch Local DB
            // Fetch Remote
            // Save Local DB
            return .suspicious
        }
        
        private func pushLocalNotification(url: URL) async throws {
            let notificationCenter = UNUserNotificationCenter.current()
            let content = makeNotificationContent(url: url)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            let request = UNNotificationRequest(identifier: "SafariWebExtensionURLScanWarning_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
            try await notificationCenter.add(request)
        }
        
        private func makeNotificationContent(url: URL) -> UNMutableNotificationContent {
            let content = UNMutableNotificationContent()
            content.title = "⚠️ Beware: \(url)"
            content.body = "(Safari) The website may be risky. Suggest leaving the site.\nCheck results →"
            content.interruptionLevel = .timeSensitive
            content.userInfo = ["SafeConnection_scan_url": url.absoluteString]
            return content
        }
    }
}

private extension NSExtensionContext {
    func convertToMessage() -> SafeConnectionSdk.SafariURLScanner.Message? {
        guard let item = inputItems.first as? NSExtensionItem,
              let object = item.userInfo?[SFExtensionMessageKey] as? [String: String],
              let action = object["action"],
              let title = object["title"],
              let urlString = object["url"],
              let url = URL(string: urlString)
        else {
            return nil
        }
        let message = SafeConnectionSdk.SafariURLScanner.Message(
            action: .init(rawValue: action),
            title: title,
            url: url
        )
        return message
    }
}

public struct ConfidenceLevel: RawRepresentable, Hashable {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public static let safe = Self(rawValue: "SAFE")
    public static let suspicious = Self(rawValue: "SUSPICIOUS")
    public static let undefined = Self(rawValue: "UNDEFINED")
    public static let malicious = Self(rawValue: "MALICIOUS")

    public var isDangerous: Bool {
        return Set([.malicious, .suspicious]).contains(self)
    }
}
