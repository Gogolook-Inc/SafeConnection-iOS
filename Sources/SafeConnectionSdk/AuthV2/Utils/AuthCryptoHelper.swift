//
//  AuthCryptoHandler.swift
//  Zonai
//
//  Created by Alex Lin Work on 2025/2/20.
//

import CryptoKit
import Foundation

class AuthCryptoHelper {
    enum CryptoError: Error {
        case cannotConvertToData
    }

    static func encryptAES128(key: Data, input: Data) throws -> Data {
        // Note:
        // CryptoKit do not support AES-CBC
        // Here will use legacy tool CommonCryptoWrapper from CentralPark
        let zipped = zip(key[0..<(key.count / 2)], key[(key.count / 2)..<key.count])
        let vector = Data(zipped.map({ $0 ^ $1 }))
        return Cryptor.encrypt(
            algorithm: .aes128,
            options: [.pkcs7Padding],
            key: key,
            iv: vector,
            plaintext: input
        ).data
    }
}

extension String {
    func sha256Hash() throws -> String {
        guard let message = self.data(using: .utf8) else {
            throw AuthCryptoHelper.CryptoError.cannotConvertToData
        }
        let hashed = SHA256.hash(data: message)

        return hashed.compactMap {
            String(format: "%02x", $0)
        }.joined()
    }
}
