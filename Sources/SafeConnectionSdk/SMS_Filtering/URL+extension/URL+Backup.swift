//
//  URL+Backup.swift
//  Whoscall
//
//  Created by ClydeHsieh on 2023/9/5.
//  Copyright © 2023 Gogolook. All rights reserved.
//

import Foundation

extension URL {
    mutating func excludeFromBackup() {
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        
        // Fix: "Escaping autoclosure captures mutating 'self' parameter" when logging in closure
        let url = self
        
        do {
            try setResourceValues(resourceValues)
        } catch {
//            #log(.error, "Failed to configure \(url.lastPathComponent) isExcludedFromBackup: \(error)")
        }
    }
}
