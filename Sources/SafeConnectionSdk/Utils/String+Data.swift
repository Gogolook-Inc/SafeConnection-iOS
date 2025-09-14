//
//  String+Data.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/5/15.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import Foundation

extension String {
    func hexStrToData() -> Data? {
        guard count.isMultiple(of: 2) else {
            return nil
        }

        var result = Data()
        for i in 0..<count / 2 {
            let startIndex = index(self.startIndex, offsetBy: i * 2)
            let endIndex = index(startIndex, offsetBy: 1)
            if let byte = UInt8(self[startIndex...endIndex], radix: 16) {
                result.append(byte)
            } else {
                return nil
            }
        }
        return result
    }
}
