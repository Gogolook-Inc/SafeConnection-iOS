//
//  Options.swift
//  SafeConnection
//
//  Created by HanyuChen on 2025/8/27.
//

public extension SafeConnectionSdk {
    struct Options {
        let properties: Properties
        
        public init(plistURL: URL?) throws {
            guard let plistURL else { throw Options.Error.missingPlistURL }
            let data = try Data(contentsOf: plistURL)
            let decoder = PropertyListDecoder()
            properties = try decoder.decode(Properties.self, from: data)
        }
    }
}

extension SafeConnectionSdk.Options {
    struct Properties: Codable {
        let environment: Environment
        let appGroupID: String
        let licenseID: String
        
        enum CodingKeys: String, CodingKey {
            case environment = "ENVIRONMENT"
            case appGroupID = "APP_GROUP_ID"
            case licenseID = "LICENSE_ID"
        }
        
        struct Environment: RawRepresentable, CustomStringConvertible, Codable, Equatable {
            var rawValue: Int
            
            static let production: Environment = .init(rawValue: 0)
            static let staging: Environment = .init(rawValue: 1)
            static let sandbox: Environment = .init(rawValue: 2)
            
            var description: String {
                switch self {
                case .production:
                    return "Production"
                case .staging:
                    return "Staging"
                case .sandbox:
                    return "Sandbox"
                default:
                    return "Unknown Environment: \(rawValue)"
                }
            }
            
            var apiURLDocumentPath: String {
                switch self {
                case .production:
                    return "API_URL_PRODUCTION"
                case .staging:
                    return "API_URL_STAGING"
                case .sandbox:
                    return "API_URL_SANDBOX"
                default:
                    fatalError("Key 'ENVIRONMENT' in SafeConnectionSDK-Info.plist  have to be 0: Production, 1: Staging or 2: sandbox, but was: \(rawValue)")
                }
            }
        }
    }
}

public extension SafeConnectionSdk.Options {
    enum Error: Swift.Error, LocalizedError {
        case missingPlistURL
        
        public var errorDescription: String? {
            switch self {
            case .missingPlistURL:
                return "SafeConnectionSdk.Options Error: Plist URL is missing. Please provide a valid plist URL."
            }
        }
    }
}
