//
//  GGLCommonErrorInfo.swift
//  melman
//
//  Created by Luis Wu on 25/08/2017.
//  Copyright © 2017 Gogolook. All rights reserved.
//

import Foundation

struct WSCCommonErrorInfo {
    static let fileKey = "WSCErrorFileKey"
    static let functionKey = "WSCErrorFunctionKey"
    static let lineKey = "WSCErrorLineKey"

    let line: Int
    let function: String
    let file: String

    init(file: String, function: String, line: Int) {
        self.file = file
        self.function = function
        self.line = line
    }
}
