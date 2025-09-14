//
//  FileHelper.swift
//  SafeConnection
//
//  Created by HanyuChen on 2025/7/2.
//

import Foundation

/// FileCoordination is unavailable in Message Filter extension in iOS 12, 14 and 15.
/// EncryptedFileHelper without crypto version
struct FileHelper {
    let fileManager = FileManager.default
    
    func save<T: Codable>(value: T, to url: URL) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        try data.write(to: url, options: .completeFileProtectionUntilFirstUserAuthentication)
    }

    func get<T: Codable>(type: T.Type, from url: URL) throws -> T {
        let decoder = JSONDecoder()
        let data = try Data(contentsOf: url)
        return try decoder.decode(type, from: data)
    }

    func remove(from url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.removeItem(at: url)
    }
    
    func fileExists(url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }
}
