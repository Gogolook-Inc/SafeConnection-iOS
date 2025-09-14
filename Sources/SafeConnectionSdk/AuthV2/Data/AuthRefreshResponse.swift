//
//  AuthRefreshResponse.swift
//  SafeConnection
//
//  Created by Michael on 2025/5/14.
//

import Foundation

class AuthRefreshResponse: Codable {
    let message: String
    let result: AuthRefreshResult

    init(message: String, result: AuthRefreshResult) {
        self.message = message
        self.result = result
    }
}

class AuthRefreshResult: Codable {
    let accessToken: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
    }

    init(accessToken: String, expiresIn: Int) {
        self.accessToken = accessToken
        self.expiresIn = expiresIn
    }
}
