//
//  LastSyncTime.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/8/30.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import Foundation
internal import RealmSwift

class LastSyncTime: Object {
    static let uniqueId: Int = 0

    @objc dynamic var syncTime: TimeInterval = 0 // 00:00:00 UTC on 1 January 1970
    @objc dynamic var id: Int = uniqueId

    // primary key
    override static func primaryKey() -> String? {
        return "id"
    }
}
