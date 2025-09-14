//
//  FakeCallDirectoryManager.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/7/18.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import CallKit
import Foundation

#if targetEnvironment(simulator)

/// This class is to allow simulators to perform actions without actually having call directory ext in system
final class FakeCallDirectoryManager: CXCallDirectoryManaging {
    func reloadExtension(withIdentifier identifier: String, completionHandler completion: ((Error?) -> Void)?) {
        SharedLocalStorage.shared.offlineDBExtCmdResult = CXCmdResult(commandTypeId: .doNothing, isSucceeded: true, errorMessage: nil)
        completion?(nil)
    }

    func getEnabledStatusForExtension(withIdentifier identifier: String, completionHandler completion: @escaping (CXCallDirectoryManager.EnabledStatus, Error?) -> Void) {
        completion(.enabled, nil)
    }

    func openSettings(completionHandler completion: ((Error?) -> Void)?) {
        completion?(nil)
    }
}
#endif
