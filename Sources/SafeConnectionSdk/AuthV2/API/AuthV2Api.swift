//
//  AuthV2Api.swift
//  SafeConnection
//
//  Created by Michael on 2025/4/25.
//

import Foundation
internal import Moya

enum AuthV2Api {
    case auth(header: String, bodyParams: [String: Any])
    case refreshToken(header: String, bodyParams: [String: Any])
}

extension AuthV2Api: TargetType {
    public var baseURL: URL {
        URL(string: OptionProvider.shared.authURL)!
    }

    public var path: String {
        switch self {
        case .auth:
            return "/auth/v2/auth"
        case .refreshToken:
            return "/auth/v2/token"
        }
    }

    var method: Moya.Method {
        switch self {
        case .auth:
            return .post
        case .refreshToken:
            return .post
        }
    }

    var task: Task {
        switch self {
        case .auth(_, let bodyParams):
            let did = bodyParams["did"] as? String ?? ""
            let licenseId = bodyParams["license_id"] as? String ?? ""
            let param = AuthRequestParameter(did: did, licenseId: licenseId, timestamp: Date.now)
            return .requestJSONEncodable(param)
        case .refreshToken:
            let key = SharedLocalStorage.shared.refreshToken.hexStrToData() ?? Data()
            let param = RefreshTokenRequestParameter(key: key, requestBodyEncryter: AuthCryptoHandler())
            return .requestJSONEncodable(param)
        }
    }
    var headers: [String: String]? {
        switch self {
        case .auth(let header, _):
            return ["Content-Type": "application/json",
                    "User-Agent": header,
                    "accept-encoding": "gzip"]
        case .refreshToken(let header, _):
            return ["Content-Type": "application/json",
                    "User-Agent": header,
                    "accept-encoding": "gzip"]
        }
    }
}
