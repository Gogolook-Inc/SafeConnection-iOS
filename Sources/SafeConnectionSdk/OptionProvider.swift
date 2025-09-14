//
//  OptionProvider.swift
//  SafeConnection
//
//  Created by HanyuChen on 2025/8/27.
//

import Foundation

final class OptionProvider {
    static let shared = OptionProvider()
    
    fileprivate struct URLConstants: Codable {
        let authURL: String
        let numURL: String
        let offlineDataBaseURL: String
        
        enum CodingKeys: String, CodingKey {
            case authURL = "AUTH_URL"
            case numURL = "NUM_URL"
            case offlineDataBaseURL = "OFFLINE_DATABASE_URL"
        }
    }
    
    private init() {}
    
    static func configure(_ options: SafeConnectionSdk.Options) throws {
        try shared.loadConfiguration(options)
    }
    
    private func loadConfiguration(_ options: SafeConnectionSdk.Options) throws {
        let apiURLDocumentPath = options.properties.environment.apiURLDocumentPath
        guard let plistURL = Bundle(for: SafeConnectionSdk.self).url(forResource: apiURLDocumentPath, withExtension: "plist") else {
            throw OptionProvider.Error.apiURLDocumentPathNotFound(apiURLDocumentPath: apiURLDocumentPath)
        }
        let data = try Data(contentsOf: plistURL)
        let decoder = PropertyListDecoder()
        _urlConstants = try decoder.decode(URLConstants.self, from: data)
        _appGroupIdentifier = options.properties.appGroupID
        _licenseID = options.properties.licenseID
    }
    
    private var _urlConstants: URLConstants?

    private var urlConstants: URLConstants {
        guard let urlConstants = _urlConstants else {
            fatalError("Configuration not loaded. Please call OptionProvider.configure() first.")
        }
        return urlConstants
    }
    
    var authURL: String {
        return urlConstants.authURL
    }
    
    var numURL: String {
        return urlConstants.numURL
    }
    
    var offlineDataBaseURL: String {
        return urlConstants.offlineDataBaseURL
    }
    
    private var _appGroupIdentifier: String?

    var appGroupIdentifier: String {
        guard let appGroupIdentifier = _appGroupIdentifier else {
            fatalError("AppGroupIdentifier not configured. Please configure it first.")
        }
        return appGroupIdentifier
    }
    
    private var _licenseID: String?

    var licenseID: String {
        guard let licenseID = _licenseID else {
            fatalError("LicenseID not configured. Please configure it first.")
        }
        return licenseID
    }
}

extension OptionProvider {
    enum Error: Swift.Error, LocalizedError {
        case apiURLDocumentPathNotFound(apiURLDocumentPath: String)
        
        var errorDescription: String? {
            switch self {
            case let .apiURLDocumentPathNotFound(apiURLDocumentPath):
                "OptionProvider Error: Can't find \(apiURLDocumentPath)"
            }
        }
    }
}
