//
//  Data+HexString.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/5/15.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import Foundation

extension Data {
    func hexadecimal() -> String {
        return self.map {
            return String(format: "%02x", $0 )
        }.joined()
    }
}
