//
//  NSError+GGLError.swift
//  melman
//
//  Created by Luis Wu on 30/08/2017.
//  Copyright © 2017 Gogolook. All rights reserved.
//

import Foundation

extension NSError {
    var rootCause: NSError {
        if let underlyingError = userInfo[NSUnderlyingErrorKey] as? NSError {
            return underlyingError.rootCause
        } else {
            return self
        }
    }

    convenience init(domain: String, code: Int, unnormalizedUserInfo dict: [String: Any]?) {
        var toBeNormalizedUserInfo = dict
        if dict != nil, dict![NSUnderlyingErrorKey] is CustomNSError {
            toBeNormalizedUserInfo![NSUnderlyingErrorKey] = dict![NSUnderlyingErrorKey] as? NSError
        }
        self.init(domain: domain, code: code, userInfo: toBeNormalizedUserInfo)
    }
}
