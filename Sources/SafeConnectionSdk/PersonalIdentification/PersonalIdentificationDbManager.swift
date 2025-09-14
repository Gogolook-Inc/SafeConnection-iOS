//
//  PersonalIdentificationDbManager.swift
//  SafeConnection
//
//  Created by Michael on 2025/7/20.
//

import CryptoKit

public class PersonalIdentificationDbManager {
    static var shared = PersonalIdentificationDbManager()
    var canRetry = true
    @AppGroupPersist(key: "PersonalIdentificationDbKeyData", defaultValue: nil, appGroupIdentifier: OptionProvider.shared.appGroupIdentifier)
    var keyData: Data?

    func getPersonalIdentificationDbURL() -> URL? {
        let appGroupIdentifier = OptionProvider.shared.appGroupIdentifier
        let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
        return url?.appendingPathComponent("personal_identification.db")
    }

    func getPersonalIdentificationDBCipherKey() throws -> Data {
        if let keyData { return keyData }
        let length = 64
        var keyData = Data(count: length)
        let result = keyData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, length, $0.baseAddress!)
        }
        guard result == errSecSuccess else {
            throw Error.keyGenerationFailed(result)
        }
        self.keyData = keyData

        let hexString = keyData.map { String(format: "%02hhx", $0) }.joined()
        print("keyData is \(hexString)")
        return keyData
    }

    func getPersonalIdentificationDBSchemaVersion() -> UInt64 {
        return 1
    }
}

extension PersonalIdentificationDbManager {
    enum Error: LocalizedError {
        case keyGenerationFailed(OSStatus)
        
        var errorDescription: String? {
            switch self {
            case .keyGenerationFailed(let status):
                return "Failed to generate cryptographic key for personal block database. Security error: \(status)"
            }
        }
    }
}
