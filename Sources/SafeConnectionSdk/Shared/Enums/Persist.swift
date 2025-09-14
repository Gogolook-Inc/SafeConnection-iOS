//
//  Persist.swift
//  SafeConnection
//
//  Created by HanyuChen on 2025/8/11.
//

import Foundation

@propertyWrapper
struct Persist<Value: Codable & Equatable> {
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
    
    init(key: String, defaultValue: Value, directory: FileManager.SearchPathDirectory = .documentDirectory) {
        self.defaultValue = defaultValue
        let directoryURL = FileManager.default.urls(for: directory, in: .userDomainMask).first!
        self.fileURL = directoryURL.appendingPathComponent(key)
    }
}

protocol OptionalProtocol {
    func isNil() -> Bool
}

extension Optional: OptionalProtocol {
    func isNil() -> Bool {
        return self == nil
    }
}
