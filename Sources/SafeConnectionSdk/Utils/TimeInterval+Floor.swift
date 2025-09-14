//
//  TimeInterval+Floor.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/3/28.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import Foundation

// MARK: - The extension is implemented to be exclusively while converting timestamps for json objects passed to user sync API v1
extension TimeInterval {
    func floorToSecond() -> Int64 {
        return Int64(floor(self))
    }

    func floorToMillisecond() -> Int64 {
        return Int64(floor(self * 1000))
    }
}
