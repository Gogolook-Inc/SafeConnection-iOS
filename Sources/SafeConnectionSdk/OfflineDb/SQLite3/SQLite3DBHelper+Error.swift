//
//  SQLite3DBHelper+Error.swift
//  Kirin
//
//  Created by Dong-Yi Wu on 2019/5/17.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import Foundation

public extension SQLite3DBHelper {
    struct Error: Swift.Error {
        public enum ErrorEnum: Int {
            case openDBFailed = -1
            case execFailed = -1001
            case prepareStmtFailed = -1002
        }
        
        public let errorEnum: ErrorEnum
        public let sqliteErrorCode: Int32
        public let message: String?
        
        public init(with errorEnum: Error.ErrorEnum, sqliteErrorCode: Int32, message: String? = nil) {
            self.errorEnum = errorEnum
            self.sqliteErrorCode = sqliteErrorCode
            self.message = message
        }
        
        public var localizedDescription: String {
            switch errorEnum {
            case .openDBFailed:
                return "Failed to open db. SQLite error code: \(sqliteErrorCode)"
            case .execFailed:
                return "Failed to execute a SQL statement. SQLite error code: \(sqliteErrorCode)"
                    + (message == nil ? "" : ", error message: \(message!)")
            case .prepareStmtFailed:
                return "Failed to prepare a SQLite statement. SQLite error code: \(sqliteErrorCode)"
            }
        }
    }
}

extension SQLite3DBHelper.Error: CustomNSError {
    public static var errorDomain = "com.gogolook.wcsdk.sqlite3_db_helper.error"
    public var errorCode: Int { errorEnum.rawValue }
}
