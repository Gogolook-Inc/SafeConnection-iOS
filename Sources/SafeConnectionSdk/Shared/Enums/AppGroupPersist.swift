//
//  AppGroupPersist.swift
//  SafeConnection
//
//  Created by HanyuChen on 2025/8/14.
//

import Foundation

@propertyWrapper
struct AppGroupPersist<Value: Codable & Equatable> {
    private let fileURL: URL
    private let defaultValue: Value
    private let fileHelper = FileHelper()
    
    public var wrappedValue: Value {
        get {
            do {
                return try fileHelper.get(type: Value.self, from: fileURL)
            } catch {
                return defaultValue
            }
        }
        set {
            do {
                if let value = newValue as? OptionalProtocol, value.isNil() {
                    try fileHelper.remove(from: fileURL)
                } else if wrappedValue != newValue {
                    try fileHelper.save(value: newValue, to: fileURL)
                } else {
                    // Ignore if values are the same
                }
            } catch {
                print("Failed to save value to file: \(error)")
            }
        }
    }
    
    // MARK: - Initializers
    
    init(key: String, defaultValue: Value, appGroupIdentifier: String) {
        self.defaultValue = defaultValue
        
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            fatalError("Invalid App Group Identifier: \(appGroupIdentifier)")
        }
        
        self.fileURL = containerURL.appendingPathComponent(key)
    }
}
