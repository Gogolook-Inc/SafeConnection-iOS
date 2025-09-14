//
//  Date+extension.swift
//  SafeConnection
//
//  Created by HanyuChen on 2025/7/1.
//

import Foundation

extension TimeInterval {
    static var oneDay: TimeInterval { 24 * 60 * 60 }
    static var oneWeek: TimeInterval { 7 * 24 * 60 * 60 }
    static var oneMonth: TimeInterval { 30 * 24 * 60 * 60 }
}

extension Date {
    /**
     Checks if another date is more than a seven-day interval from this date.

     - Parameter date: The date to compare against.
     - Returns: `true` if the absolute difference between the two dates is greater than seven days; otherwise, `false`.
    */
    func over7Days(of date: Date) -> Bool {
        let sevenDaysInSeconds: TimeInterval = .oneWeek
        let timeDifference = abs(self.timeIntervalSince(date))
        return timeDifference > sevenDaysInSeconds
    }
    
    // This method is for debug
    func over7Seconds(of date: Date) -> Bool {
        let sevenDaysInSeconds: TimeInterval = 7
        let timeDifference = abs(self.timeIntervalSince(date))
        return timeDifference > sevenDaysInSeconds
    }
}
