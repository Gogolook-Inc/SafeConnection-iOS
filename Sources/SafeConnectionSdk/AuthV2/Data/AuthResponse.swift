//
//  AuthResponse.swift
//  SafeConnection
//
//  Created by Michael on 2025/5/14.
//

import Foundation

class AuthResponse: Codable {
    let message: String
    let result: AuthResult

    init(message: String, result: AuthResult) {
        self.message = message
        self.result = result
    }
}

class AuthResult: Codable {
    let uid: String
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let region: String

    enum CodingKeys: String, CodingKey {
        case uid
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case region = "region"
    }

    init(uid: String, accessToken: String, refreshToken: String, expiresIn: Int, region: String) {
        self.uid = uid
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.region = region
    }
}
