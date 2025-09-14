//
//  SafeConnectionError.swift
//  SafeConnection
//
//  Created by Michael on 2025/5/9.
//

enum SafeConnectionError: Error {
    case notInitialized
    case dbAlreadyLatest
    case dbDownloadFail
    case dbUnzipFail
    case dbDecompressFail
}
