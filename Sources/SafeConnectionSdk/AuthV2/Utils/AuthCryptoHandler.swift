//
//  AuthCryptoHandler.swift
//  SafeConnection
//
//  Created by Michael on 2025/5/15.
//

public class AuthCryptoHandler: APINonceGenerating, APIAuthRequestBodyEncrypting {
    func generateNonce(input: String) -> String {
        let message = input.data(using: .utf8)
        assert(message != nil, "Even if the input is an empty string, message would not be nil.")
        return SHA(algorithm: .sha256).digest(message: message!).hexadecimal()
    }

    func encrypt(key: Data, input: Data) throws -> Data {
        let zipped = zip(key[0..<(key.count / 2)], key[(key.count / 2)..<key.count])
        let iv = Data(zipped.map({ $0 ^ $1 }))
        return Cryptor.encrypt(algorithm: .aes128, options: [.pkcs7Padding], key: key, iv: iv, plaintext: input).data
    }
}
