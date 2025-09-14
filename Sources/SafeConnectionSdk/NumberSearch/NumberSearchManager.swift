//
//  NumberSearchManager.swift
//  SafeConnection
//
//  Created by Michael on 2025/4/30.
//

internal import Moya

public class NumberSearchManager {
    static var shared = NumberSearchManager()
    var canRetry = true

    func searchNumber(e164: String) async throws -> NumberInfo {
        print("searchNumber e164: \(e164)")
        let signed = SharedLocalStorage.shared.signed
//        print("signed = \(signed)")
        var numberInfo: NumberInfo = NumberInfo(e164: e164)
        do {
            if signed.isEmpty {
                numberInfo = try await searchApiServer(e164: e164)
            } else {
                numberInfo = try await searchCdnServer(e164: e164)
            }
        } catch let error as NSError {
            if !canRetry || error.code != 403 {
                throw error
            } else {
                print("403 continue to retry auth")
            }
        }
        let accessToken = SharedLocalStorage.shared.accessToken
        let refreshToken = SharedLocalStorage.shared.refreshToken
        print("accessToken = \(accessToken), canRetry = \(canRetry)")
        if accessToken.isEmpty && refreshToken.isEmpty && canRetry {
            print("retrying auth...")
            canRetry = false
            _ = try await AuthV2Manager.shared.authV2()
            numberInfo = try await searchNumber(e164: e164)
        } else if accessToken.isEmpty && canRetry {
            print("retrying refresh...")
            canRetry = false
            _ = try await AuthV2Manager.shared.refreshV2()
            numberInfo = try await searchNumber(e164: e164)
        }
        return numberInfo
    }

    private func searchApiServer(e164: String) async throws -> NumberInfo {
        print("searchApiServer")
        let provider = MoyaProvider<NumberSearchApi>()
        var numberInfo = NumberInfo(e164: e164)
        let region = SharedLocalStorage.shared.region
        return try await withCheckedThrowingContinuation { continuation in
            provider.request(.search(signed: "1", region: region, number: e164)) { result in
                switch result {
                case .success(let response):
                    print("Status Code: \(response.statusCode)")
                    if  response.statusCode == 200,
                        let data = try? response.mapJSON() as? [String: Any] {
//                        print("Response Data: \(data)")
                        numberInfo.name = data["name"] as? String ?? ""
                        numberInfo.bussinessCategory = data["bizcate"] as? String ?? ""
                        numberInfo.spam = data["spam"] as? String ?? ""
                        numberInfo.spamLevel = data["spamlevel"] as? Int ?? 0

                        let signed = data["signed"] as? String ?? ""
                        SharedLocalStorage.shared.signed = signed
                        self.recordToDb(e164: e164, region: region, body: response.data)
                        continuation.resume(returning: numberInfo)
                    } else {
                        if response.statusCode == 403 {
                            SharedLocalStorage.shared.accessToken = ""
                            SharedLocalStorage.shared.signed = ""
                        }
                        continuation.resume(throwing: NSError(domain: "", code: response.statusCode, userInfo: nil))
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func searchCdnServer(e164: String) async throws -> NumberInfo {
        print("searchCdnServer")
        let signedParams = SharedLocalStorage.shared.signed.toStringStringMap()
        let region = SharedLocalStorage.shared.region
        let provider = MoyaProvider<NumberSearchApi>()
        var numberInfo = NumberInfo(e164: e164)

        return try await withCheckedThrowingContinuation { continuation in
            provider.request(.searchFromCdn(signedParams: signedParams, region: region, number: e164)) { result in
                switch result {
                case .success(let response):
                    print("Status Code: \(response.statusCode)")
                    if  response.statusCode == 200,
                        let data = try? response.mapJSON() as? [String: Any] {
//                        print("Response Data: \(data)")
                        numberInfo.name = data["name"] as? String ?? ""
                        numberInfo.bussinessCategory = data["bizcate"] as? String ?? ""
                        numberInfo.spam = data["spam"] as? String ?? ""
                        numberInfo.spamLevel = data["spamlevel"] as? Int ?? 0

                        self.recordToDb(e164: e164, region: region, body: response.data)
                        continuation.resume(returning: numberInfo)
                    } else {
                        if response.statusCode == 403 {
                            SharedLocalStorage.shared.accessToken = ""
                            SharedLocalStorage.shared.signed = ""
                        }
                        continuation.resume(throwing: NSError(domain: "", code: response.statusCode, userInfo: nil))
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func recordToDb(e164: String, region: String, body: Data) {
        guard let numberObject = try? self.makeNumberObject(from: body) else {
            return
        }
        let phoneNumberInfo = try? PhoneNumberInfo(number: e164, region: region, numberObject: numberObject)
        DispatchQueue.global().async {
            do {
                //logger.info("Begin to write value into db")
                try SearchHistoryDBHelper().add(entries: [phoneNumberInfo!], updatePolicy: .error)
                //logger.info("Write value into db successfully")

                CallDirectoryManager.shared.updateAndGetEnabledStatusForExtension(.identification) { granted in
                    guard granted else { return }
                    CallDirectoryManager.shared.reload(extension: .identification) { result in
                        switch result {
                        case .failure(let error):
                                print("Failed to reload personal identification CX, error: \(error)")
                        case .success:
                                print("Personal identification CX successfully reloaded")
                        }
                    }
                }
            } catch let error as SearchHistoryDBHelper.Error {
                switch error.errorEnum {
                    case SearchHistoryDBHelper.Error.ErrorEnum.entryAlreadyExists:
                        do {
                            //logger.info("Begin to update phone number info")
                            phoneNumberInfo!.isInSearchHistory = true
                            try SearchHistoryDBHelper().add(entries: [phoneNumberInfo!], updatePolicy: .modified)
                            print("Update phone number info successfully")
                        } catch {
                            print("Failed to write value into db, error: \(error)")
                        }
                    default:
                        print("Failed to write value into db, error: \(error)")
                }
            } catch {
                print("Failed to write value into db, error: \(error)")
            }
        }
    }

    private func makeNumberObject(from data: Data) throws -> WCNumberObject {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let object = try decoder.decode(WCNumberObject.self, from: data)
        return object
    }
}

private extension String {
    func toStringStringMap() -> [String: String] {
        return self.split(separator: "&").reduce(into: [String: String]()) { result, subString in
            let nameValue = subString.split(separator: "=")
            if nameValue.count == 2 {
                if let name = nameValue.first, let value = nameValue.last {
                    result[String(name)] = String(value)
                }
            }
        }
    }
}
