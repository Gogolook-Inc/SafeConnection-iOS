//
//  OfflineDbManager.swift
//  SafeConnection
//
//  Created by Michael on 2025/4/27.
//

import Foundation
internal import Moya
internal import ZipArchive

protocol Compressible {
    func compress(srcURL: URL, dstURL: URL, progressClosure: (Int64) -> Void) throws
    func decompress(srcURL: URL, dstURL: URL, progressClosure: (Int64) -> Void) throws
}
extension CompressionCodec: Compressible {}

public class OfflineDbManager {
    static var shared = OfflineDbManager()
    var canRetry = true

    func checkToRefreshOfflineDb() async throws -> String {

        var result = try await refreshOfflineDb()

        let accessToken = SharedLocalStorage.shared.accessToken
        let refreshToken = SharedLocalStorage.shared.refreshToken
        print("accessToken = \(accessToken), canRetry = \(canRetry)")
        if accessToken.isEmpty && refreshToken.isEmpty && canRetry {
            print("retrying auth...")
            canRetry = false
            _ = try await AuthV2Manager.shared.authV2()
            result = try await refreshOfflineDb()
        } else if accessToken.isEmpty && canRetry {
            print("retrying refresh...")
            canRetry = false
            _ = try await AuthV2Manager.shared.refreshV2()
            result = try await refreshOfflineDb()
        }
        return result
    }

    func refreshOfflineDb() async throws -> String {
        let provider = MoyaProvider<OfflineDbApi>()
        var resultString = ""
        let region = SharedLocalStorage.shared.region
        return try await withCheckedThrowingContinuation { continuation in
            provider.request(.getOfflineDbProfile(version: "9.0", region: region)) { result in
                switch result {
                case .success(let response):
                    print("Status Code: \(response.statusCode)")
                    if response.statusCode == 200,
                        let data = try? response.mapJSON() as? [String: Any] {
                        print("Response Data: \(data)")
                        let dbFileName = data["file_name"] as? String ?? ""
//                        let dbType = data["db_type"] as? String ?? ""
                        let updateTime = data["update_time"] as? String ?? ""
                        let nextDbVersion = data["version"] as? Int ?? 0
                        let dbDownloadUrl = data["url"] as? String ?? ""
                        let key = data["key"] as? String ?? ""
                        SharedLocalStorage.shared.dbFileName = dbFileName
                        SharedLocalStorage.shared.nextDbVersion = nextDbVersion
                        SharedLocalStorage.shared.dbDownloadUrl = dbDownloadUrl
                        AppGroupLocalStorage.shared.dbKey = key

                        let checksums = data["checksums"] as? String ?? ""
                        SharedLocalStorage.shared.updateTimestamp = updateTime
                        SharedLocalStorage.shared.checksums = checksums
                        print("updatedTime = \(updateTime)\nchecksums = \(checksums)\n dbKey = \(key)")
                        resultString = "db nextDbVersion = \(nextDbVersion)\ndownloadUrl = \(dbDownloadUrl)\n dbKey = \(key)"
                    } else if response.statusCode == 403 {
                        SharedLocalStorage.shared.accessToken = ""
                    } else {
                        resultString = "Error: \(response.statusCode)"
                    }
                    continuation.resume(returning: resultString)
                case .failure(let error):
                    // 處理錯誤
                    print("Error: \(error) \(error.localizedDescription)")
                    continuation.resume(returning: error.localizedDescription)
                }
            }
        }
    }
    func downloadOfflineDb() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            var resultString = ""
            let dbFileName: String = SharedLocalStorage.shared.dbFileName
            let documentsDirectoryURL = getSharedContainerURL()
            let localDatabaseURL = documentsDirectoryURL?.appendingPathComponent(dbFileName)
            guard localDatabaseURL != nil else {
                resultString = "localDatabaseURL is nil"
                continuation.resume(returning: resultString)
                return
            }
            let url = SharedLocalStorage.shared.dbDownloadUrl
            guard url.isEmpty == false else {
                resultString = "url is empty"
                continuation.resume(returning: resultString)
                return
            }
            let provider = MoyaProvider<OfflineDbApi>()
            let destination: DownloadDestination = { _, response in
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let fileURL = documentsURL.appendingPathComponent(response.suggestedFilename ?? "downloaded_file")
                return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
            }
            print("download url = \(url)")
            print("download destination = \(String(describing: destination))")
            provider.request(
                .downloadOfflineDb(url: url, destination: destination),
                progress: { progress in
                    print("download progress：\(progress.progress)")
                },
                completion: { result in
                    switch result {
                    case .success(let response):
                        if response.statusCode == 200 {
                            do {
                                print("response data length：\(response.data.count)")
                                try response.data.write(to: localDatabaseURL!)
                                print("db download success，save to：\(localDatabaseURL!)")
                                SharedLocalStorage.shared.dbDownloadedPath = localDatabaseURL!.path
                                resultString = "db download success，save to：\(localDatabaseURL!)"
                                let nextDbVer = SharedLocalStorage.shared.nextDbVersion
                                SharedLocalStorage.shared.currentDbVersion = nextDbVer
                                continuation.resume(returning: resultString)
                            } catch {
                                print("db download fail：\(error)")
                                resultString = "db download fail：\(error)"
                                continuation.resume(returning: resultString)
                            }
                        } else {
                            resultString = "db download fail, statusCode: \(response.statusCode)"
                            continuation.resume(returning: resultString)
                        }

                    case .failure(let error):
                        print("db download fail：\(error)")
                        resultString = "db download fail：\(error)"
                        continuation.resume(returning: resultString)
                    }
                }
            )
        }
    }

    func unzipDb() async throws -> String {
        let dbDownloadedPath = SharedLocalStorage.shared.dbDownloadedPath
        guard dbDownloadedPath.isEmpty == false else {
            return "error, url is empty"
        }
        print("dbDownloadedPath = \(dbDownloadedPath)")
        let fileExists = FileManager.default.fileExists(atPath: dbDownloadedPath)
        print("fileExists: \(fileExists)")

        guard FileManager.default.fileExists(atPath: dbDownloadedPath) else {
            print("dbPath not exist")
            return "error, url exists, but db is not downloaded"
        }

        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dbUnzipPath = documentsDirectory.appendingPathComponent("unzippedFile").path
        SharedLocalStorage.shared.dbUnzipPath = dbUnzipPath
        print("file size = \(String(describing: getFileSize(atPath: dbDownloadedPath)))")
        let timeStamp10Digit = SharedLocalStorage.shared.updateTimestamp.prefix(10)
        let checksums = SharedLocalStorage.shared.checksums
        let password = "\(timeStamp10Digit)\(checksums)"
        print("unzipDbPath = \(dbUnzipPath), password = \(password)")
        do {
            try SSZipArchive.unzipFile(atPath: dbDownloadedPath, toDestination: dbUnzipPath, overwrite: true, password: password)
            print("unzip success")
            return ("unzip success, path = \(dbUnzipPath)")
        } catch {
            print("error \(error)")
            return ("error \(error)")
        }
    }

    func getFileSize(atPath path: String) -> Int64? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            if let fileSize = attributes[.size] as? NSNumber {
                return fileSize.int64Value
            }
        } catch {
            print("Error getting file attributes: \(error)")
        }
        return nil
    }

    func decompressDb() async throws -> String {
        let dbUnzipUrl = URL(fileURLWithPath: SharedLocalStorage.shared.dbUnzipPath).appendingPathComponent("data")
        let dbDecompressedUrl = getSharedDatabaseURL()
        let compressionCodec: Compressible = CompressionCodec(.lzma, bufferSize: 4096)

        let filesize = ((try? FileManager.default.attributesOfItem(atPath: dbUnzipUrl.path)) as NSDictionary?)?.fileSize() ?? 0
        guard filesize > 0 else {
            print("db file size is 0")
            return "error, db file size is 0"
        }
        // remove old db

        if FileManager.default.fileExists(atPath: dbDecompressedUrl!.path) {
            do {
                try FileManager.default.removeItem(at: dbDecompressedUrl!)
                print("old db removed successfully")
            } catch {
                print("error: \(error.localizedDescription)")
            }
        }

        do {
            try compressionCodec.decompress(srcURL: dbUnzipUrl, dstURL: dbDecompressedUrl!) { progress in
                var percentage = 0.0
                if filesize > 0 {
                    percentage = Double(progress) / Double(filesize)
                }
                print("progress: \(percentage)")
//                self.progressCallback?(.decompressing(progress: percentage))
            }
            print("decompress success path = \(dbDecompressedUrl!.path)")
            return "decompress success path = \(dbDecompressedUrl!.path)"
        } catch {
            print("deCompressed error: \(error)")
            return "deCompressed error: \(error)"
        }
    }

    func clearCommonDb(completion: ((Result<Void, Error>) -> Void)?) async throws {
        print("clearCommonDb")
        SharedLocalStorage.shared.dbFileName = ""
        SharedLocalStorage.shared.currentDbVersion = 0
        SharedLocalStorage.shared.nextDbVersion = 0
        SharedLocalStorage.shared.dbDownloadUrl = ""
        SharedLocalStorage.shared.updateTimestamp = ""
        SharedLocalStorage.shared.checksums = ""

        let dbDownloadedPath = URL(fileURLWithPath: SharedLocalStorage.shared.dbDownloadedPath)
        let dbUnzipUrl = URL(fileURLWithPath: SharedLocalStorage.shared.dbUnzipPath).appendingPathComponent("data")
        let dbDecompressedUrl = getSharedDatabaseURL()

        do {
            try FileManager.default.removeItem(at: dbDownloadedPath)
        } catch {
            print("Failed to remove dbDownloadedPath file error: \(error)")
        }
        do {
            try FileManager.default.removeItem(at: dbUnzipUrl)
        } catch {
            print("Failed to remove dbUnzipUrl file error: \(error)")
        }
        do {
            try FileManager.default.removeItem(at: dbDecompressedUrl!)
        } catch {
            print("Failed to remove dbDecompressedUrl file error: \(error)")
        }
        completion?(.success(()))
    }

    func getSharedContainerURL() -> URL? {
        let appGroupIdentifier = OptionProvider.shared.appGroupIdentifier
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }

    func getSharedDatabaseURL() -> URL? {
        return getSharedContainerURL()?.appendingPathComponent("decompressed.db")
    }
}
