//
//  NumberSearchApi.swift
//  Auth
//
//  Created by Michael on 2025/4/24.
//

internal import Moya

enum NumberSearchApi {
    case searchFromCdn(signedParams: [String: Any], region: String, number: String)
    case search(signed: String, region: String, number: String)
}

// 遵循 TargetType 協議
extension NumberSearchApi: TargetType {
    var baseURL: URL {
        URL(string: OptionProvider.shared.numURL)!
    }

    var path: String {
        switch self {
        case let .searchFromCdn(_, region, number):
            return "/search/v11/\(region)/\(number)"
        case let .search(_, region, number):
            return "/searchback/v11/\(region)/\(number)"
        }
    }

    var method: Moya.Method {
        switch self {
        case .searchFromCdn:
            return .get
        case .search:
            return .get
        }
    }

    var task: Moya.Task {
        switch self {
        case .searchFromCdn(let parameters, _, _):
            return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
        case .search(let signed, _, _):
            return .requestParameters(parameters: ["signed": signed], encoding: URLEncoding.default)
        }
    }

//    var sampleData: Data {
//        switch self {
//        case .searchFromCdn(let signedParams, let region, let number):
//            return "{\"id\":, \"name\": \"Test User\"}".data(using: .utf8)!
//        case .search(let signed, let region, let number):
//            return "{\"id\":, \"name\": \"Test User\"}".data(using: .utf8)!
//        }
//    }

    var headers: [String: String]? {
        let sharedDefaults = SharedLocalStorage.shared
        return ["Content-Type": "application/json", "User-Agent": "\(sharedDefaults.userAgent)", "accesstoken": "\(sharedDefaults.accessToken)", "accept-encoding": "gzip"]
    }
}
