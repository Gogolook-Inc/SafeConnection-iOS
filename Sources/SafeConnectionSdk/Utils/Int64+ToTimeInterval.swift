//
//  Int64+ToTimeInterval.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/3/28.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import Foundation

// MARK: - The extension is implemented to be exclusively while converting timestamps getting from user sync API's results
extension Int64 {
    func toTimeInterval() -> TimeInterval {
        return TimeInterval(self)
    }

    func fromMilliSecondToTimeInterval() -> TimeInterval {
        return TimeInterval(self) / 1000
    }
}
