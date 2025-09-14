//
//  GGLError.swift
//  melman
//
//  Created by Luis Wu on 25/08/2017.
//  Copyright © 2017 Gogolook. All rights reserved.
//

import Foundation

// Default implementation
extension WSCError {
    var internalUserInfo: [String: Any] {
        var userInfo: [String: Any] = [:]
        if let underlyingError = self.underlyingError {
            userInfo[NSUnderlyingErrorKey] = underlyingError as NSError
        }
        if let internalImpl = self.commonErrorInfo {
            userInfo[WSCCommonErrorInfo.fileKey] = internalImpl.file
            userInfo[WSCCommonErrorInfo.functionKey] = internalImpl.function
            userInfo[WSCCommonErrorInfo.lineKey] = internalImpl.line
        }

        return userInfo
    }

    var rootCause: Error {
        if let underlyingError = (self as NSError).userInfo[NSUnderlyingErrorKey] as? NSError {
            return underlyingError.rootCause
        } else {
            return self
        }
    }
}
