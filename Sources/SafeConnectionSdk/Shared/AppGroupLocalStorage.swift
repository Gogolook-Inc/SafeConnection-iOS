//
//  AppGroupLocalStorage.swift
//  SafeConnection
//
//  Created by HanyuChen on 2025/8/14.
//

import Foundation

final class AppGroupLocalStorage {
    
    static let shared = AppGroupLocalStorage()
    
    private init() { }
    
    enum Key: String, CaseIterable {
        case dbKey
    }
    
    @AppGroupPersist(key: Key.dbKey.rawValue, defaultValue: "", appGroupIdentifier: OptionProvider.shared.appGroupIdentifier)
    var dbKey: String
}
