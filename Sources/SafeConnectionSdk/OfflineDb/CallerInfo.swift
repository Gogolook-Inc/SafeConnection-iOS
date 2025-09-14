//
//  CallerInfo.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/5/14.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import CallKit

/// The structure holding a caller's information, mainly used to denote a identification entry.
public struct CallerInfo {
    var number: CXCallDirectoryPhoneNumber
    var name: String
    var type: CallerType?
}
