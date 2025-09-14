//
//  CallDirExt.swift
//  Merli
//
//  Created by Henry Tseng on 2019/5/3.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import Foundation

/// Call directory extensions available
///
/// - offlineDB: Offline DB call directory extension
/// - identification: personal identification call directory extension
/// - blocking: personal blocking call directory extension
/// - instantDB: Instant DB call directory extension
enum CallDirExt: String, CaseIterable {

    case offlineDB
    case identification
    case blocking

    var identifier: String {
        switch self {
        case .offlineDB:
            return "com.gogolook.whsocallsdk.Example.OfflineDb"
        case .identification:
            return "com.gogolook.whsocallsdk.Example.PersonalIdentification"
        case .blocking:
            return "com.gogolook.whsocallsdk.Example.PersonalBlocking"
        }
    }
}
