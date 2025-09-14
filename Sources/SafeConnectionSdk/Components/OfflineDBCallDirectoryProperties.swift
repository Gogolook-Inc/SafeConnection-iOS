//
//  OfflineDBCallDirectoryProperties.swift
//  Kirin
//
//  Created by Henry Tseng on 2020/8/11.
//  Copyright © 2020 Gogolook. All rights reserved.
//

import Foundation

protocol OfflineDBCallDirectoryProperties {
    /// The command type identifier to be read by Offline DB call dir ext. Offline DB call dir ext make and execute the command according to the value
    var offlineDBExtCmdType: CXCmdTypeIdentifier { get set }

    /// The result of the last execution of command occurred in Offline DB call dir ext
    var offlineDBExtCmdResult: CXCmdResult? { get set }
}

extension SharedLocalStorage: OfflineDBCallDirectoryProperties {}
