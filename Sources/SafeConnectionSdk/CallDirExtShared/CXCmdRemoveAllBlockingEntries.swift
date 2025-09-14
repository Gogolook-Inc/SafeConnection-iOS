//
//  CXCmdRemoveAllBlockingEntries.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/5/14.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import CallKit

class CXCmdRemoveAllBlockingEntries: CXCommand {
    private let context: CXCallDirectoryExtensionContext
    private let commandTypeId: CXCmdTypeIdentifier

    init(context: CXCallDirectoryExtensionContext) {
        self.context = context
        commandTypeId = .removeAllBlockingEntries
    }

    func execute() -> CXCmdResult {
        if context.isIncremental {
            context.removeAllBlockingEntries()
        }
        return CXCmdResult(commandTypeId: commandTypeId, isSucceeded: true, errorMessage: nil)
    }
}
