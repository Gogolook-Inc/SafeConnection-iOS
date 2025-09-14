//
//  SQLite3+Foundation.swift
//  CentralPark
//
//  Created by willsbor Kang on 2019/3/11.
//  Copyright © 2019年 gogolook. All rights reserved.
//

import Foundation
import SQLite3

let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

class WCSQLite3 {
    
    enum Errors: Error {
        case openDBFailed
        case sqlitePrepareError(Int32)
        case sqliteStepNotDone(Int32)
        case sqliteFinalizeError(Int32, String)
        case bindError(String)
        case multiRowsDBNotUpdate(Int32, String)
        case multiRowsResetError(Int32, String)
        case beginTransactionFailed(Int32, String)
        case rollbackTransactionFailed(Int32, String, Error)
        case commitTransactionFailed(Int32, String)
    }
    
    private var db: OpaquePointer?
    let fileURL: URL
    let scheme: String
    
    var isOpened: Bool {
        return db != nil
    }
    
    var errorMessage: String {
        guard let db = db else {
            return ""
        }
        return String(cString: sqlite3_errmsg(db))
    }
    
    init(_ fileURL: URL, _ scheme: String) {
        self.fileURL = fileURL
        self.scheme = scheme
    }
    
    func call(_ command: String, _ handler: ((OpaquePointer?) throws -> Void)? = nil, _ resultHandler: ((OpaquePointer?) throws -> Void)? = nil) throws {

        guard openDBIfNeed(), let db = db else {
            throw Errors.openDBFailed
        }
        
        var statement: OpaquePointer?
        
        defer {
            sqlite3_finalize(statement)
            closeDBIfNeed()
        }
        
        let state = sqlite3_prepare_v2(db, command, -1, &statement, nil)
        if state == SQLITE_OK {
            try handler?(statement)
            
            var state = sqlite3_step(statement)
            while state == SQLITE_ROW {
                try resultHandler?(statement)
                state = sqlite3_step(statement)
            }
            
            if state != SQLITE_DONE {
                throw Errors.sqliteStepNotDone(state)
            }
        } else {
            throw Errors.sqlitePrepareError(state)
        }
    }
    
    func insertMultiRows<T>(_ command: String, _ dataArray: [T], _ handler: ((OpaquePointer?, T) throws -> Void)) throws {
        guard openDBIfNeed(), let db = db else {
            throw Errors.openDBFailed
        }
        
        defer {
            closeDBIfNeed()
        }
        
        var state = sqlite3_exec(db, "BEGIN TRANSACTION", nil, nil, nil)
        guard state == SQLITE_OK else {
            throw Errors.beginTransactionFailed(state, errorMessage)
        }
        var statement: OpaquePointer?
        defer {
            sqlite3_finalize(statement)
        }
        
        do {
            state = sqlite3_prepare_v2(db, command, -1, &statement, nil)
            guard state == SQLITE_OK else {
                throw Errors.sqlitePrepareError(state)
            }
            
            try dataArray.forEach { item in
                try handler(statement, item)
                
                state = sqlite3_step(statement)
                if state != SQLITE_DONE {
                    throw Errors.multiRowsDBNotUpdate(state, errorMessage)
                }
                state = sqlite3_reset(statement)
                if state != SQLITE_OK {
                    throw Errors.multiRowsResetError(state, errorMessage)
                }
            }
            
            state = sqlite3_finalize(statement)
            statement = nil
            guard state == SQLITE_OK else {
                throw Errors.sqliteFinalizeError(state, errorMessage)
            }
            
            state = sqlite3_exec(db, "COMMIT TRANSACTION", nil, nil, nil)
            guard state == SQLITE_OK else {
                throw Errors.commitTransactionFailed(state, errorMessage)
            }
        } catch {
            state = sqlite3_exec(db, "ROLLBACK TRANSACTION", nil, nil, nil)
            guard state == SQLITE_OK else {
                throw Errors.rollbackTransactionFailed(state, errorMessage, error)
            }
            
            throw error
        }
    }
    
    func openDBIfNeed() -> Bool {
        if isOpened {
            return true
        }
        
        if sqlite3_open(fileURL.path, &db) == SQLITE_OK {
            if sqlite3_exec(db, scheme, nil, nil, nil) == SQLITE_OK {
                return true
            } else {
                sqlite3_close(db)
                db = nil
                return false
            }
        } else {
            db = nil
            return false
        }
    }
    
    func closeDBIfNeed() {
        guard isOpened else {
            return
        }
        
        sqlite3_close(db)
        db = nil
    }
}
