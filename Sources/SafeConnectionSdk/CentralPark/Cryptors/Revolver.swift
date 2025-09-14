//
//  Revolver.swift
//  Kirin
//
//  Created by Dong-Yi Wu on 2019/5/2.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import Foundation

/// An implementation of Vigenère cipher. Please read [the document]
/// (https://paper.dropbox.com/doc/Whoscall-iOS-3.0--AcV~bcq1vFq6ahFws18oKrDeAg-sA5tE6bznJTBjTV0XAGzk#:uid=795309310126896865969294&h2=Revolver) for details.
public class Revolver {
    private let encryptionRoulette: Data

    private lazy var decryptionRoulette: [UInt8: UInt8] = { () -> [UInt8: UInt8] in
        var roulette: [UInt8: UInt8] = [:]
        for i in 0 ..< encryptionRoulette.count {
            roulette[encryptionRoulette[i]] = UInt8(i)
        }
        return roulette
    }()

    public convenience init() {
        var codeWords = Data(0x0...0xf)
        codeWords.shuffle()
        self.init(encryptionRoulette: codeWords)
    }

    public init(encryptionRoulette: Data) {
//        guard Set(encryptionRoulette).count == 0x10 else {
//            throw Error(with: .invalidEncryptionKey)
//        }
        self.encryptionRoulette = encryptionRoulette
    }

    public func encrypt(data: Data, iv: Int) -> Data {
        var encryptedData = Data(data)
        var triggerCount = iv

        for byte in encryptedData {
            let lowNibble = byte & 0x0F
            let highNibble = (byte >> 4) & 0x0F
            let highNibbleEncodeIndex = (Int(highNibble) + triggerCount) % encryptionRoulette.count
            let lowNibbleEncodeIndex = (Int(lowNibble) + triggerCount) % encryptionRoulette.count
            let convertedByte = (encryptionRoulette[Int(highNibbleEncodeIndex)] << 4) | encryptionRoulette[Int(lowNibbleEncodeIndex)]
            encryptedData[triggerCount - iv] = convertedByte
            // rotate the roulette (pull trigger)
            triggerCount += 1
        }
        return encryptedData
    }

    public func decrypt(data: Data, iv: Int) -> Data {
        var decryptedData = Data(data)
        var triggerCount = iv
        var normalizedTriggerCount = triggerCount % encryptionRoulette.count

        for byte in decryptedData {
            let lowNibble: UInt8 = byte & 0x0F
            let highNibble: UInt8 = (byte >> 4) & 0x0F
            // swiftlint:disable:next line_length operator_usage_whitespace
            let convertedHighNibble = decryptionRoulette[highNibble]! < UInt8(normalizedTriggerCount) ? UInt8(encryptionRoulette.count) - (UInt8(normalizedTriggerCount) - decryptionRoulette[highNibble]!) :  decryptionRoulette[highNibble]! - UInt8(normalizedTriggerCount)
            // swiftlint:disable:next line_length operator_usage_whitespace
            let convertedLowNibble = decryptionRoulette[lowNibble]! < UInt8(normalizedTriggerCount) ? UInt8(encryptionRoulette.count) - (UInt8(normalizedTriggerCount) - decryptionRoulette[lowNibble]!) :  decryptionRoulette[lowNibble]! - UInt8(normalizedTriggerCount)
            let convertedByte = (convertedHighNibble << 4) | convertedLowNibble
            decryptedData[triggerCount - iv] = convertedByte
            // rotate the roulette
            triggerCount += 1
            normalizedTriggerCount = (triggerCount) % encryptionRoulette.count
        }
        return decryptedData
    }
}
