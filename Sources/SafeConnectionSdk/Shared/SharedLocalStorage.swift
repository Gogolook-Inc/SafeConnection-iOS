//
//  SharedLocalStorage.swift
//  SafeConnection
//
//  Created by HanyuChen on 2025/8/11.
//

import Foundation
import UIKit.UIDevice

final class SharedLocalStorage {
    
    static let shared = SharedLocalStorage()
    
    private init() { }
    
    enum Key: String, CaseIterable {
        case signed
        case accessToken
        case refreshToken
        case userAgent
        case uid
        case did
        case region
        case dbFileName
        case currentDbVersion
        case nextDbVersion
        case dbDownloadUrl
        case dbKey
        case updateTimestamp
        case checksums
        case dbDownloadedPath
        case dbUnzipPath
        case offlineDBExtCmdType
        case offlineDBExtCmdResult
    }

    @Persist(key: Key.signed.rawValue, defaultValue: "")
    var signed: String

    @Persist(key: Key.accessToken.rawValue, defaultValue: "")
    var accessToken: String

    @Persist(key: Key.refreshToken.rawValue, defaultValue: "")
    var refreshToken: String

    @Persist(key: Key.userAgent.rawValue, defaultValue: nil)
    private var _userAgent: String?
    
    var userAgent: String {
        get {
            if let storeUa = _userAgent {
                return storeUa
            } else {
                let ua = [
                    OptionProvider.shared.licenseID,
                    "1000000",
                    uid,
                    did,
                    "ios",
                    normalizeSystemVersion(UIDevice.current.systemVersion)
                ].joined(separator: "|")
                if uid != did {
                    _userAgent = ua
                }
                return ua
            }
        }
        set {
            _userAgent = newValue
        }
    }

    func clearUserAgent() {
        _userAgent = nil
    }

    private func normalizeSystemVersion(_ version: String) -> String {
        let threePartRegex = #"^\d+\.\d+\.\d+$"#
        let isThreePartVersion = NSPredicate(format: "SELF MATCHES %@", threePartRegex).evaluate(with: version)
        if isThreePartVersion {
            return version
        }
        let twoPartRegex = #"^\d+\.\d+$"#
        let isTwoPartVersion = NSPredicate(format: "SELF MATCHES %@", twoPartRegex).evaluate(with: version)
        if isTwoPartVersion {
            let normalizedVersion = version + ".0"
            return normalizedVersion
        }
        return version
    }

    @Persist(key: Key.uid.rawValue, defaultValue: nil)
    private var _uid: String?
    
    var uid: String {
        get {
            if let storedUid = _uid {
                return storedUid
            } else {
                return did
            }
        }
        set {
            _uid = newValue
        }
    }

    @Persist(key: Key.did.rawValue, defaultValue: nil)
    private var _did: String?
    
    var did: String {
        get {
            if let storedDid = _did {
                return storedDid
            } else {
                let newDid = UUID().uuidString.replacingOccurrences(of: "-", with: "")
                _did = newDid
                return newDid
            }
        }
        set {
            _did = newValue
        }
    }

    @Persist(key: Key.region.rawValue, defaultValue: "JP")
    var region: String

    @Persist(key: Key.dbFileName.rawValue, defaultValue: "")
    var dbFileName: String

    @Persist(key: Key.currentDbVersion.rawValue, defaultValue: 0)
    var currentDbVersion: Int

    @Persist(key: Key.nextDbVersion.rawValue, defaultValue: 0)
    var nextDbVersion: Int

    @Persist(key: Key.dbDownloadUrl.rawValue, defaultValue: "")
    var dbDownloadUrl: String

    @Persist(key: Key.updateTimestamp.rawValue, defaultValue: "")
    var updateTimestamp: String

    @Persist(key: Key.checksums.rawValue, defaultValue: "")
    var checksums: String

    @Persist(key: Key.dbDownloadedPath.rawValue, defaultValue: "")
    var dbDownloadedPath: String

    @Persist(key: Key.dbUnzipPath.rawValue, defaultValue: "")
    var dbUnzipPath: String
    
    @Persist(key: Key.offlineDBExtCmdType.rawValue, defaultValue: 0)
    private var _offlineDBExtCmdType: Int
    
    var offlineDBExtCmdType: CXCmdTypeIdentifier {
        get {
            CXCmdTypeIdentifier(rawValue: _offlineDBExtCmdType)!
        }
        set {
            _offlineDBExtCmdType = newValue.rawValue
        }
    }
    
    @Persist(key: Key.offlineDBExtCmdResult.rawValue, defaultValue: nil)
    var offlineDBExtCmdResult: CXCmdResult?

    func reset() {
        let fileHelper = FileHelper()
        let directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        for key in Key.allCases {
            let url = directoryURL.appendingPathComponent(key.rawValue)
            do {
                try fileHelper.remove(from: url)
            } catch {
                print(#file, #line, "Can't remove \(key.rawValue): Error: \(error)")
            }
        }
    }
}
