//
//  AuthV2Manager.swift
//  SafeConnection
//
//  Created by Michael on 2025/5/13.
//

internal import Moya

class AuthV2Manager {
    static var shared = AuthV2Manager()

    func authV2() async throws -> AuthResponse {
        let header = SharedLocalStorage.shared.userAgent
        let bodyParams = getAuthBodyParams()

        let provider = MoyaProvider<AuthV2Api>()

        return try await withCheckedThrowingContinuation { continuation in
            provider.request(.auth(header: header, bodyParams: bodyParams)) { result in
                switch result {
                case .success(let response):
                    print("Status Code: \(response.statusCode)")
                    guard response.statusCode == 200 else {
                        continuation.resume(throwing: APIError.invalidStatusCode(response.statusCode, response.data))
                        return
                    }
                    do {
                        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: response.data)
                        SharedLocalStorage.shared.accessToken = authResponse.result.accessToken
                        SharedLocalStorage.shared.refreshToken = authResponse.result.refreshToken
                        SharedLocalStorage.shared.uid = authResponse.result.uid
                        SharedLocalStorage.shared.region = authResponse.result.region
                        continuation.resume(returning: authResponse)
                    } catch {
                        continuation.resume(throwing: APIError.decodingError(error))
                    }

                case .failure(let error):
                    print("error \(error)")
                    SharedLocalStorage.shared.clearUserAgent()
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func refreshV2() async throws -> AuthRefreshResponse {
        let header = SharedLocalStorage.shared.userAgent
        let refreshToken = SharedLocalStorage.shared.refreshToken
        guard !refreshToken.isEmpty else {
            return AuthRefreshResponse(
                message: "refresh token is empty",
                result: AuthRefreshResult(accessToken: "", expiresIn: 0)
            )
        }
        let bodyParams = ["refresh_token": refreshToken]

        let provider = MoyaProvider<AuthV2Api>()

        return try await withCheckedThrowingContinuation { continuation in
            provider.request(.refreshToken(header: header, bodyParams: bodyParams)) { result in
                switch result {
                case .success(let response):
                    print("Status Code: \(response.statusCode)")
                    guard response.statusCode == 200 else {
                        continuation.resume(throwing: APIError.invalidStatusCode(response.statusCode, response.data))
                        return
                    }
                    do {
                        let refreshResponse = try JSONDecoder().decode(AuthRefreshResponse.self, from: response.data)
                        SharedLocalStorage.shared.accessToken = refreshResponse.result.accessToken
                        continuation.resume(returning: refreshResponse)
                    } catch {
                        continuation.resume(throwing: APIError.decodingError(error))
                    }

                case .failure(let error):
                    SharedLocalStorage.shared.clearUserAgent()
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func getAuthBodyParams() -> [String: Any] {
        var params: [String: Any] = [:]
        params["license_id"] = OptionProvider.shared.licenseID
        params["did"] = SharedLocalStorage.shared.did
        print("body \(params)")
        return params
    }
}

enum APIError: Error {
    case invalidStatusCode(Int, Data)
    case decodingError(Error)
    case moyaError(MoyaError)
    case unknownError
}

enum CodingKeys: String, CodingKey {
    case deviceID = "did"
    case licenseId = "license_id"
    case timestamp = "timestamp"
    case nonce = "nonce"
}
