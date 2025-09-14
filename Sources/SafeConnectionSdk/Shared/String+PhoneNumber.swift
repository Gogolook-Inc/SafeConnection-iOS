//
//  String+PhoneNumber.swift
//  Merli
//
//  Created by Henry Tseng on 2019/7/8.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import Foundation

extension String {
    func removePhoneNumberSignCharacters() -> String {
        // NOTE: \u202d: left-to-right override: overrides the bidirectional text to left-to-right.
        //       \u202c (pop directional formatting): terminates an embedding or override control.
        // What are they for? Ref: https://www.informationsecurity.com.tw/answers/answer_detail.aspx?tid=50

        let removalCharacters = CharacterSet(charactersIn: "()+- \u{202D}\u{202C}")
        let number = self.components(separatedBy: removalCharacters).joined()
        return number
    }

    var isValidPhoneNumber: Bool {
        let availableCharacters = CharacterSet(charactersIn: "0123456789()+- \u{202D}\u{202C}")
        return (self.rangeOfCharacter(from: availableCharacters.inverted) == nil)
    }

    func obfuscateDisplayNumber(maxLength: Int = 4) -> String {
        let length = min(self.count, maxLength)
        let beginIndex = self.index(self.endIndex, offsetBy: -length)

        let replacedText = String(repeating: "*", count: length)
        return self.replacingCharacters(in: beginIndex..<self.endIndex, with: replacedText)
    }
}
