//
//  OfflineDbApi.swift
//  SafeConnection
//
//  Created by Michael on 2025/4/25.
//

internal import Moya

enum OfflineDbApi {
    case getOfflineDbProfile(version: String, region: String)
    case downloadOfflineDb(url: String, destination: DownloadDestination)
}

extension OfflineDbApi: TargetType {
    public var baseURL: URL {
        switch self {
        case .getOfflineDbProfile:
            return URL(string: OptionProvider.shared.offlineDataBaseURL)!
        case .downloadOfflineDb(let url, _):
            return URL(string: url)!
        }
    }

    public var path: String {
        switch self {
        case let .getOfflineDbProfile(version, region):
            return "/offline/cgdb/ios/v\(version)/\(region)"
        case .downloadOfflineDb:
            return ""
        }
    }

    var method: Moya.Method {
        switch self {
        case .getOfflineDbProfile:
            return .get
        case .downloadOfflineDb:
            return .get
        }
    }

    var task: Task {
        switch self {
        case .getOfflineDbProfile:
            return .requestPlain
        case .downloadOfflineDb:
            return .requestPlain
        }
    }
    var headers: [String: String]? {
        let sharedLocalStorage = SharedLocalStorage.shared
        return ["Content-Type": "application/json", "User-Agent": "\(sharedLocalStorage.userAgent)", "accesstoken": "\(sharedLocalStorage.accessToken)", "accept-encoding": "gzip"]
    }
}
