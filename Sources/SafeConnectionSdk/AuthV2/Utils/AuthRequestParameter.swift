//
//  AuthRequestParameter.swift
//  SafeConnection
//
//  Created by Michael on 2025/5/15.
//

struct AuthRequestParameter: Encodable {
    enum CodingKeys: String, CodingKey {
        case deviceID = "did"
        case licenseId = "license_id"
        case timestamp = "timestamp"
        case nonce = "nonce"
    }

    let did: String
    let licenseId: String
    let timestamp: Int

    init(did: String, licenseId: String, timestamp: Date) {
        self.timestamp = Int(Date().timeIntervalSince1970) * 1000
        self.did = did
        self.licenseId = licenseId
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(did, forKey: .deviceID)
        try container.encode(licenseId, forKey: .licenseId)
        try container.encode(timestamp, forKey: .timestamp)

        var nonceInputs: [CodingKeys: String] = [
            .deviceID: did,
            .timestamp: String(describing: timestamp)
        ]
        nonceInputs[.licenseId] = licenseId
        let nonce = try NonceGenerator().generateNonce(from: nonceInputs)

        print("AuthRequestParameter \(nonceInputs)")

        try container.encode(nonce, forKey: .nonce)
    }
}
