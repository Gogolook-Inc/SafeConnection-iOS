//
//  Realm+UpdateProperties.swift
//  Merli
//
//  Created by Henry Tseng on 2019/10/28.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import Foundation
internal import RealmSwift

extension Realm {
    /// To update an entry with properties of another unmanaged entry
    /// - Parameter targetEntry: The managed entry need to be updated
    /// - Parameter unmanagedEntry: The unmanaged entry with updated values
    func update<T: Object>(_ targetEntry: T, with unmanagedEntry: T) {
        let primaryKeyProperty = T.sharedSchema()!.primaryKeyProperty
        let nonPrimaryKeyProperties = T.sharedSchema()!.properties.drop(while: { property -> Bool in
            return property == primaryKeyProperty
        })
        for property in nonPrimaryKeyProperties {
            targetEntry.setValue(unmanagedEntry.value(forKey: property.name), forKey: property.name)
        }
    }
}
