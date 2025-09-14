//
//  RefreshTokenRequestParameter.swift
//  SafeConnection
//
//  Created by Michael on 2025/5/15.
//

struct RefreshTokenRequestParameter: Encodable {
    private struct RawData: Encodable {
        let timestamp: Int

        private enum CodingKeys: String, CodingKey {
            case timestamp
        }
    }

    private let rawData: RawData
    private let key: Data
    private let requestBodyEncryter: APIAuthRequestBodyEncrypting

    init(key: Data, requestBodyEncryter: APIAuthRequestBodyEncrypting) {
        let timestamp = Int(Date().timeIntervalSince1970)
        self.rawData = RawData(timestamp: timestamp)
        self.key = key
        self.requestBodyEncryter = requestBodyEncryter
    }

    private enum CodingKeys: String, CodingKey {
        case data
    }

    func encode(to encoder: Encoder) throws {
        let internalEncoder = JSONEncoder()
        let jsonRawData = try internalEncoder.encode(rawData)
        let encryptedData = try requestBodyEncryter.encrypt(key: key, input: jsonRawData).hexadecimal()

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(encryptedData, forKey: .data)
    }
}
