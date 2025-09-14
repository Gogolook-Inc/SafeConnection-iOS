//
//  CXCmdRemoveAllIdentificationEntries.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/5/14.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import CallKit

class CXCmdRemoveAllIdentificationEntries: CXCommand {
    private let context: CXCallDirectoryExtensionContext
    private let commandTypeId: CXCmdTypeIdentifier

    init(context: CXCallDirectoryExtensionContext) {
        self.context = context
        commandTypeId = .removeAllIdentificationEntries
    }

    func execute() -> CXCmdResult {
        if context.isIncremental {
            context.removeAllIdentificationEntries()
        }
        return CXCmdResult(commandTypeId: commandTypeId, isSucceeded: true, errorMessage: nil)
    }
}
