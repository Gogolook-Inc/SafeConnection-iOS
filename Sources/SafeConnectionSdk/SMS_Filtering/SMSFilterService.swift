//
//  SMSFilterService.swift
//  SafeConnection
//
//  Created by HanyuChen on 2025/7/9.
//

import Foundation

class SMSFilterService {
    enum SMSFilterError: Error, LocalizedError {
        case invalidURL
        case noData
        case decodingError(Error)
        case networkError(Error)
        case httpError(Int)

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "The URL provided was invalid."
            case .noData:
                return "No data was returned from the server."
            case .decodingError(let error):
                return "Failed to decode the server response: \(error.localizedDescription)"
            case .networkError(let error):
                return "A network error occurred: \(error.localizedDescription)"
            case .httpError(let statusCode):
                return "Server returned an HTTP error: \(statusCode)"
            }
        }
    }

    private struct SMSFilterResponse: Decodable {
        let url: String
    }

    private let hostURL = OptionProvider.shared.authURL
    
    private var canRetry = true

    func getCDNURL(region: String, accessToken: String, userAgent: String) async throws -> [MessageFilterRuleContainer] {
        guard !accessToken.isEmpty, !canRetry else {
            canRetry = false
            let result = try await AuthV2Manager.shared.authV2()
            let newUserAgent = SharedLocalStorage.shared.userAgent
            return try await getCDNURL(region: region, accessToken: result.result.accessToken, userAgent: newUserAgent)
        }
        
        guard let url = URL(string: "\(hostURL)/sms/filter/v1/\(region)") else {
            throw SMSFilterError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(accessToken, forHTTPHeaderField: "accesstoken")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SMSFilterError.networkError(URLError(.badServerResponse))
        }

        guard httpResponse.statusCode != 403, !canRetry else {
            canRetry = false
            let result = try await AuthV2Manager.shared.refreshV2()
            let newUserAgent = SharedLocalStorage.shared.userAgent
            return try await getCDNURL(region: region, accessToken: result.result.accessToken, userAgent: newUserAgent)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw SMSFilterError.httpError(httpResponse.statusCode)
        }

        do {
            let decodedResponse = try JSONDecoder().decode(SMSFilterResponse.self, from: data)
            let containers = try await getDataFromCDN(cdnURL: decodedResponse.url)
            return containers
        } catch {
            throw SMSFilterError.decodingError(error)
        }
    }

    private func getDataFromCDN(cdnURL: String) async throws -> [MessageFilterRuleContainer] {
        guard let url = URL(string: cdnURL) else {
            throw SMSFilterError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SMSFilterService.SMSFilterError.networkError(URLError(.badServerResponse))
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw SMSFilterService.SMSFilterError.httpError(httpResponse.statusCode)
        }
        
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        let containers = try MessageFilterRuleContainer.makeContainers(from: json)
        return containers
    }
}
