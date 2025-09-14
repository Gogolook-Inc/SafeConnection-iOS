//
//  SQLiteDBHelper.swift
//  Kirin
//
//  Created by Dong-Yi Wu on 2019/5/14.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import Foundation
import SQLite3

// NOTE: WCSQLite3 could be combined with this class.
public final class SQLite3DBHelper {
    private let db: OpaquePointer
    private let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
    private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    
    /// Constructor. it opens the db directly
    ///
    /// - Parameters:
    ///   - dbURL: the URL of the SQLite 3 DB. If the file specified by the URL doesn't exit, the function throws an error
    ///   - fileOpenFlags: SQLite file open flags
    /// - Throws: errors while opening the DB
    public init(dbURL: URL, fileOpenFlags: Int32 = SQLITE_OPEN_READONLY) throws { // SQLITE_OPEN_READONLY doesn't create file while the file doesn't exist
        var dbRef: OpaquePointer?
        let result = sqlite3_open_v2(dbURL.path, &dbRef, fileOpenFlags, nil)
        guard result == SQLITE_OK, let db = dbRef else {
            throw Error(with: .openDBFailed, sqliteErrorCode: result)
        }
        self.db = db
    }
    
    /// Close DB. It's the caller's responsability to close the DB when finished.
    public func close() {
        sqlite3_close(db)
    }
    
    /// execute a SQL statement
    ///
    /// - Parameter sqlStmt: the SQL statement to execute
    /// - Throws: errors while executing the statement
    public func exec(sqlStmt: String) throws {
        try autoreleasepool {
            var errMsg: UnsafeMutablePointer<CChar>?
            let result = sqlite3_exec(db, sqlStmt, nil, nil, &errMsg)
            guard result == SQLITE_OK || result == SQLITE_DONE else {
                throw Error(with: .execFailed, sqliteErrorCode: result, message: errMsg != nil ? String(cString: errMsg!) : nil)
            }
        }
    }
    
    /// Prepare a SQL statement
    ///
    /// - Parameter sqlStmt: the SQL statement to prepare to
    /// - Returns: the pointer to point the returned prepared SQL statement
    /// - Throws: errors while preparing the statemet
    public func prepare(sqlStmt: String) throws -> OpaquePointer {
        var sqlStmtPtr: OpaquePointer?
        let result = sqlite3_prepare_v2(db, sqlStmt, -1, &sqlStmtPtr, nil)
//        let result = sqlite3_prepare_v3(db, sqlStmt, -1, 0, &sqlStmtPtr, nil)     // only available on iOS 12+
        guard result == SQLITE_OK, sqlStmtPtr != nil else {
            throw Error(with: .prepareStmtFailed, sqliteErrorCode: result)
        }
        return sqlStmtPtr!
    }
    
    /// Advance a SQL statement to the next result row or completion
    ///
    /// - Parameter sqlStmtPtr: a pointer pointing to a prepared statement from where the result row comes
    /// - Returns: result or error code of SQLite
    public func step(sqlStmtPtr: OpaquePointer) -> Int32 {
        return sqlite3_step(sqlStmtPtr)
    }
    
    /// Get the content of a column as `Int32`, specified by `colNum`, from a prepared SQL statement
    ///
    /// - Parameters:
    ///   - sqlStmtPtr: a pointer pointing to a prepared statement
    ///   - colNum: the number that indicates the given column (start from 0)
    /// - Returns:  result or error code of SQLite
    public func columnInt32(sqlStmtPtr: OpaquePointer, colNum: Int32) -> Int32 {
        return sqlite3_column_int(sqlStmtPtr, colNum)
    }
    
    /// Get the content of a column as `Int64`, specified by `colNum`, from a prepared SQL statement
    ///
    /// - Parameters:
    ///   - sqlStmtPtr: a pointer pointing to a prepared statement
    ///   - colNum: the number that indicates the given column (start from 0)
    /// - Returns:  result or error code of SQLite
    public func columnInt64(sqlStmtPtr: OpaquePointer, colNum: Int32) -> Int64 {
        return sqlite3_column_int64(sqlStmtPtr, colNum)
    }
    
    /// Get the content of a column as TEXT (casted to `String`), specified by `colNum`, from a prepared SQL statement
    ///
    /// - Parameters:
    ///   - sqlStmtPtr: a pointer pointing to a prepared statement
    ///   - colNum: the number that indicates the given column (start from 0)
    /// - Returns:  result or error code of SQLite
    public func columnText(sqlStmtPtr: OpaquePointer, colNum: Int32) -> String {
        return String(cString: sqlite3_column_text(sqlStmtPtr, colNum))
    }
    
    /// Get the content of a column as a binary large object, specified by `colNum`, from a prepared SQL statement
    ///
    /// - Parameters:
    ///   - sqlStmtPtr: a pointer pointing to a prepared statement
    ///   - colNum: the number that indicates the given column (start from 0)
    /// - Returns:  result or error code of SQLite
    public func columnBLOB(sqlStmtPtr: OpaquePointer, colNum: Int32) -> Data {
        if let ptr = sqlite3_column_blob(sqlStmtPtr, colNum) {
            return Data(bytes: ptr, count: Int(sqlite3_column_bytes(sqlStmtPtr, colNum)))
        } else {    // boundary condition: name BLOB is not NULL yet no content
            return Data()
        }
    }
    
    /// Get the content of a column as `Double`, specified by `colNum`, from a prepared SQL statement
    ///
    /// - Parameters:
    ///   - sqlStmtPtr: a pointer pointing to a prepared statement
    ///   - colNum: the number that indicates the given column (start from 0)
    /// - Returns:  result or error code of SQLite
    public func columnDouble(sqlStmtPtr: OpaquePointer, colNum: Int32) -> Double {
        return sqlite3_column_double(sqlStmtPtr, colNum)
    }

    /// bind a int SQL parameter to a SQL statement
    ///
    /// - Parameters:
    ///   - sqlStmtPtr: a pointer pointing to a prepared statement
    ///   - index: the index of the SQL parameter to be set. The leftmost SQL parameter has an index of 1
    ///   - value: the value to bind to (must be between 1 and the sqlite3_limit())
    /// - Returns:  result or error code of SQLite
    public func bindInt(sqlStmtPtr: OpaquePointer, index: Int32, value: Int32) -> Int32 {
        return sqlite3_bind_int(sqlStmtPtr, index, value)
    }
    
    /// bind a int64 SQL parameter to a SQL statement
    ///
    /// - Parameters:
    ///   - sqlStmtPtr: a pointer pointing to a prepared statement
    ///   - index: the index of the SQL parameter to be set. The leftmost SQL parameter has an index of 1
    ///   - value: the value to bind to
    /// - Returns:  result or error code of SQLite
    public func bindInt64(sqlStmtPtr: OpaquePointer, index: Int32, value: Int64) -> Int32 {
        return sqlite3_bind_int64(sqlStmtPtr, index, value)
    }
    
    /// bind a text SQL parameter to a SQL statement
    ///
    /// - Parameters:
    ///   - sqlStmtPtr: a pointer pointing to a prepared statement
    ///   - index: the index of the SQL parameter to be set. The leftmost SQL parameter has an index of 1
    ///   - value: the value to bind to
    /// - Returns:  result or error code of SQLite
    public func bindText(sqlStmtPtr: OpaquePointer, index: Int32, value: String) -> Int32 {
        return value.withCString { cStrPtr -> Int32 in
            return sqlite3_bind_text(sqlStmtPtr, index, cStrPtr, -1, SQLITE_TRANSIENT)
        }
    }
    
    /// bind a BLOB SQL parameter to a SQL statement
    ///
    /// - Parameters:
    ///   - sqlStmtPtr: a pointer pointing to a prepared statement
    ///   - index: the index of the SQL parameter to be set. The leftmost SQL parameter has an index of 1
    ///   - value: the value to bind to
    /// - Returns:  result or error code of SQLite
    public func bindBlob(sqlStmtPtr: OpaquePointer, index: Int32, value: Data) -> Int32 {
        return value.withUnsafeBytes { rawBufferPtr -> Int32 in
            return sqlite3_bind_blob(sqlStmtPtr, index, rawBufferPtr.baseAddress, Int32(rawBufferPtr.count), SQLITE_TRANSIENT)
        }
    }
    
    /// Destruct a prepared SQL statement
    ///
    /// - Parameter sqlStmtPtr: the pointer pointing to the to-be-destructed prepared statement
    public func finalize(sqlStmtPtr: OpaquePointer) {
        sqlite3_finalize(sqlStmtPtr)
    }
}
