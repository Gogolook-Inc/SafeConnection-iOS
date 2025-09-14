// The Swift Programming Language
// https://docs.swift.org/swift-book

import CallKit
internal import Moya
import UIKit

// TODO: This category is used to show how to use Auth
// and how to get Token, please remove this file after
// you know how to use it.

public class SafeConnectionSdk {
    private static var inited = false

    public enum Environment: String {
        case staging
        case sandbox
        case production
    }

    public init() {}

    public func search(e164: String) async throws -> NumberInfo {
        if !SafeConnectionSdk.inited {
            throw SafeConnectionError.notInitialized
        }
        print("search \(e164)")
        return try await NumberSearchManager.shared.searchNumber(e164: e164)
    }

    public func refreshOfflineDb() async throws -> String {
        if !SafeConnectionSdk.inited {
            throw SafeConnectionError.notInitialized
        }
        return try await OfflineDbManager.shared.checkToRefreshOfflineDb()
    }

    public func downloadOfflineDb() async throws -> String {
        if !SafeConnectionSdk.inited {
            throw SafeConnectionError.notInitialized
        }
        let currentDb = try getCurrentCommonDbProfileString()
        let nextDb = try getNextCommonDbProfileString()
        guard currentDb == "0" || currentDb != nextDb else {
            throw SafeConnectionError.dbAlreadyLatest
        }
        let result = try await OfflineDbManager.shared.downloadOfflineDb()
        guard !result.contains("error") else {
            throw SafeConnectionError.dbDownloadFail
        }
        let result2 = try await OfflineDbManager.shared.unzipDb()
        guard !result2.contains("error") else {
            throw SafeConnectionError.dbUnzipFail
        }
        let result3 = try await decompressDb()
        guard !result3.contains("error") else {
            throw SafeConnectionError.dbDecompressFail
        }
        return result + "\n" + result2 + "\n" + result3
    }

    public func unzipDb() async throws -> String {
        if !SafeConnectionSdk.inited {
            throw SafeConnectionError.notInitialized
        }
        let result = try await OfflineDbManager.shared.unzipDb()
        let result2 = try await decompressDb()
        return result + "\n" + result2
    }

    func decompressDb() async throws -> String {
        if !SafeConnectionSdk.inited {
            throw SafeConnectionError.notInitialized
        }
        return try await OfflineDbManager.shared.decompressDb()
    }

    func setCallerId() async throws -> String {
        if !SafeConnectionSdk.inited {
            throw SafeConnectionError.notInitialized
        }
        return ""
    }

    public func getCurrentCommonDbProfileString() throws -> String {
        if !SafeConnectionSdk.inited {
            throw SafeConnectionError.notInitialized
        }
        return String(SharedLocalStorage.shared.currentDbVersion)
    }

    public func getNextCommonDbProfileString() throws -> String {
        if !SafeConnectionSdk.inited {
            throw SafeConnectionError.notInitialized
        }
        return String(SharedLocalStorage.shared.nextDbVersion)
    }

    public func clearCommonDb(completion: ((Result<Void, Error>) -> Void)?) async throws {
        if !SafeConnectionSdk.inited {
            throw SafeConnectionError.notInitialized
        }
        try await OfflineDbManager.shared.clearCommonDb(completion: completion)
    }

    public static func loadDbEntries(context: CXCallDirectoryExtensionContext, blockTopSpamNumbers: Bool) {
        guard let dbURL = OfflineDbManager.shared.getSharedDatabaseURL() else {
            print("Extension cannot get shared db URL")
            context.completeRequest()
            return
        }
        let dbKey = AppGroupLocalStorage.shared.dbKey
        guard !dbKey.isEmpty else {
            print("empty dbKey")
            context.completeRequest()
            return
        }
        let cipherKey: Data = dbKey.hexStrToData()!
        let entryProvider = try? DeltaSQLiteDBEntryProvider(dbURL: dbURL, cipherKey: cipherKey)
        guard entryProvider != nil else {
            context.completeRequest()
            return
        }

        do {
            let result = try CXCmdOfflineDBLoadEntries(context: context, entryProvider: entryProvider!, blockTopSpamNumbers: true).execute()
            print("result \(result)")
        } catch {
            print("error \(error.localizedDescription)")
            dumpError(error: error)
        }
    }

    static func dumpError(error:Error) {
        let errorMessage = error.localizedDescription
        switch errorMessage {
            case let msg where msg.contains("error 0"):
                print("unknown, An unknown error occurred.")
            case let msg where msg.contains("error 1"):
                print("noExtensionFound, The call directory manager could not find a corresponding app extension.")
            case let msg where msg.contains("error 2"):
                print("currentlyLoading, The call directory manager is loading the app extension.")
            case let msg where msg.contains("error 3"):
                print("loadingInterrupted, The call directory manager was interrupted while loading the app extension.")
            case let msg where msg.contains("error 4"):
                print("entriesOutOfOrder, The entries in the call directory are out of order.")
            case let msg where msg.contains("error 5"):
                print("duplicateEntries, There are duplicate entries in the call directory.")
            case let msg where msg.contains("error 6"):
                print("maximumEntriesExceeded, There are too many entries in the call directory.")
            case let msg where msg.contains("error 7"):
                print("extensionDisabled, The call directory extension isn’t enabled by the system.")
            case let msg where msg.contains("error 8"):
                print("unexpectedIncrementalRemoval, A request occurred before confirming incremental loading.")
            default:
                print("others：\(errorMessage)")
        }
    }

    public static func loadPersonalBlockingEntries(context: CXCallDirectoryExtensionContext) {
        guard let dbURL = PersonalBlockDbManager.shared.getPersonalBlockDbURL() else {
            print("Extension cannot get shared db URL")
            context.completeRequest()
            return
        }
        guard let cipherKey = try? PersonalBlockDbManager.shared.getPersonalBlockingDBCipherKey() else {
            print("Extension cannot get cipherkey")
            context.completeRequest()
            return
        }
        let entryProvider = try? DeltaRealmDBBlockingEntryProvider(dbURL: dbURL, cipherKey: cipherKey, schemaVersion: 1)
        guard entryProvider != nil else {
            context.completeRequest()
            return
        }

        do {
            let result = try CXCmdPersonalBlockingLoadEntries(context: context, entryProvider: entryProvider!, tryLoadIncrementalEntrySet: false).execute()
            print("result \(result)")
        } catch {
            print("error \(error.localizedDescription)")
            dumpError(error: error)
        }
    }

    public static func loadPersonalIdentificationEntries(context: CXCallDirectoryExtensionContext) {
        guard let dbURL = PersonalIdentificationDbManager.shared.getPersonalIdentificationDbURL() else {
            print("Extension cannot get shared db URL")
            context.completeRequest()
            return
        }
        guard let cipherKey = try? PersonalIdentificationDbManager.shared.getPersonalIdentificationDBCipherKey() else {
            print("Extension cannot get cipherkey")
            context.completeRequest()
            return
        }

        let entryProvider = DeltaRealmDBIdentificationEntryProvider(dbURL: dbURL, cipherKey: cipherKey, schemaVersion: 1)

        do {
            let result = try CXCmdPersonalIdentificationLoadEntries(context: context, entryProvider: entryProvider, tryLoadIncrementalEntrySet: false).execute()
            print("result \(result)")
        } catch {
            print("error \(error.localizedDescription)")
            dumpError(error: error)
        }
    }

    public func blockNumber(number: String) async -> Result<Void, Error> {

        var phoneNumber: Int64!
        let regionCode = SharedLocalStorage.shared.region
        if let fullNumber = try? PhoneNumberUtil(number: number.removePhoneNumberSignCharacters()).getE164WithRegion(regionCode), let e164 = Int64(fullNumber) {
            phoneNumber = e164
        } else if let n = Int64(number.removePhoneNumberSignCharacters()) {
            phoneNumber = n
        } else {
            //            presenter.presentErrorAlert(InputError.invalidNumber)
            //logger.error("Fail to add number to block list", error: InputError.invalidNumber)
            let error = NSError(domain: CXErrorCodeCallDirectoryManagerError.errorDomain, code: 1001, userInfo:  [NSLocalizedDescriptionKey: "invalidNumber"])
            return .failure(error)
        }
        do {
            try await PhoneNumberBlocker().block(phoneNumber, regionCode: regionCode)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    public func unblockNumber(number: String) async -> Result<Void, Error> {
        var phoneNumber: Int64!
        let regionCode = SharedLocalStorage.shared.region
        if let fullNumber = try? PhoneNumberUtil(number: number.removePhoneNumberSignCharacters()).getE164WithRegion(regionCode), let e164 = Int64(fullNumber) {
            phoneNumber = e164
        } else if let n = Int64(number.removePhoneNumberSignCharacters()) {
            phoneNumber = n
        } else {
            //            presenter.presentErrorAlert(InputError.invalidNumber)
            //logger.error("Fail to add number to block list", error: InputError.invalidNumber)
            let error = NSError(
                domain: CXErrorCodeCallDirectoryManagerError.errorDomain,
                code: 1001,
                userInfo:  [NSLocalizedDescriptionKey: "invalidNumber"]
            )
            return .failure(error)
        }

        do {
            try await PhoneNumberBlocker().unblock(phoneNumber)
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}

public extension SafeConnectionSdk {
    static func configure() throws {
        let url = Bundle.main.url(forResource: "SafeConnectionSDK-Info", withExtension: "plist")
        let options = try Options(plistURL: url)
        try configure(options)
    }

    static func configure(_ options: Options) throws {
        try OptionProvider.configure(options)
        inited = true
    }

    var appGroupIdentifier: String {
        OptionProvider.shared.appGroupIdentifier
    }
}
