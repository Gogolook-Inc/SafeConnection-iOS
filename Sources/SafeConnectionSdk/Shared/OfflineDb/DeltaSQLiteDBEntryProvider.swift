//
//  DeltaSQLiteDBEntryProvider.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/5/14.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import CallKit
import os
import SQLite3
/// It provides entries to call directory extensions. This class was designed to serve offline db call dir ext, reading entries from a SQLite DB.
public class DeltaSQLiteDBEntryProvider: CXOfflineDBEntryProviding {
    private var sqlite3Helper: SQLite3DBHelper
    private let dbURL: URL
    private let cipherKey: Data
    private let revolver: Revolver  // the cipher to decrypt number and name of a caller info

    /// Constructor
    ///
    /// - Parameters:
    ///   - dbURL: the URL where offline DB is at
    ///   - cipherKey: Revolver's cipher key
    /// - Throws: errors while opening DB
    public init(dbURL: URL, cipherKey: Data) throws {
        self.dbURL = dbURL
        self.sqlite3Helper = try SQLite3DBHelper(dbURL: self.dbURL)
        self.cipherKey = cipherKey
        print("dbURL = \(self.dbURL)")
        self.revolver = Revolver(encryptionRoulette: cipherKey)
    }

    deinit {
        sqlite3Helper.close()
    }

    // MARK: CXOfflineDBEntryProviding

    public func provideCompleteIdentificationEntries(onNextValue: (CallerInfo) -> Void) throws {
        let log = OSLog(subsystem: "com.gogolook.whsocallsdk.Example.PersonalIdentification", category: "debug")
        os_log(.debug, log: log, "This is a debug message: provideCompleteIdentificationEntries")
        try sqlite3Helper.exec(sqlStmt: "PRAGMA journal_mode = MEMORY")
        let sqlStmtPtr = try sqlite3Helper.prepare(sqlStmt: "SELECT id, number, type, name FROM CallerInfo WHERE (delta & ?) = 0x1 ORDER BY id ASC")
        let deltaMask = Delta.add.rawValue
        let bindDeltaMaskResult = sqlite3Helper.bindInt(sqlStmtPtr: sqlStmtPtr, index: 1, value: deltaMask)
        guard bindDeltaMaskResult == SQLITE_OK else {
            throw Error(with: .bindDeltaMaskError(sqliteErrorCode: bindDeltaMaskResult))
        }
        provideIdentificationEntries(for: .add, sqlStmtPtr: sqlStmtPtr, onNextValue: onNextValue)
        sqlite3Helper.finalize(sqlStmtPtr: sqlStmtPtr)
    }

    public func provideCompleteBlockingEntries(onNextValue: (CXCallDirectoryPhoneNumber) -> Void) throws {
        try sqlite3Helper.exec(sqlStmt: "PRAGMA journal_mode = MEMORY")
        let sqlStmtPtr = try sqlite3Helper.prepare(sqlStmt: "SELECT id, number FROM CallerInfo WHERE (delta & ?) = 0x1 AND type & ? = 1  ORDER BY id ASC")
        let deltaMask = Delta.add.rawValue
        let bindDeltaMaskResult = sqlite3Helper.bindInt(sqlStmtPtr: sqlStmtPtr, index: 1, value: deltaMask)
        guard bindDeltaMaskResult == SQLITE_OK else {
            throw Error(with: .bindDeltaMaskError(sqliteErrorCode: bindDeltaMaskResult))
        }
        let typeMask = Int32(CallerType.topSpam.rawValue)
        let bindTypeMaskResult = sqlite3Helper.bindInt(sqlStmtPtr: sqlStmtPtr, index: 2, value: typeMask)
        guard bindTypeMaskResult == SQLITE_OK else {
            throw Error(with: .bindTypeMaskError(sqliteErrorCode: bindTypeMaskResult))
        }

        provideBlockingEntries(sqlStmtPtr: sqlStmtPtr, onNextValue: onNextValue)
        sqlite3Helper.finalize(sqlStmtPtr: sqlStmtPtr)
    }

    func provideIncrementalIdentificationEntries(diffId: Int, for action: Action, onNextValue: (CallerInfo) -> Void) throws {
        try sqlite3Helper.exec(sqlStmt: "PRAGMA journal_mode = MEMORY")
        let sqlStmtPtr = try sqlite3Helper.prepare(sqlStmt: """
            SELECT id, number, type, name FROM CallerInfo
                WHERE ((delta & ?) = ? OR (delta & ?) = ?)
                ORDER BY id ASC
        """)

        let deltaMask = Delta.updateLabel.rawValue << (2 * diffId)
        var givenActionDeltaValue = Delta.noAction.rawValue // to determine add or remove
        switch action {
        case .add:
            givenActionDeltaValue = Delta.add.rawValue << (2 * diffId)
        case .remove:
            givenActionDeltaValue = Delta.remove.rawValue << (2 * diffId)
        }
        let updateLabelDeltaValue = Delta.updateLabel.rawValue << (2 * diffId)

        var bindResult = sqlite3Helper.bindInt(sqlStmtPtr: sqlStmtPtr, index: 1, value: deltaMask)
        guard bindResult == SQLITE_OK else {
            throw Error(with: .bindDeltaMaskError(sqliteErrorCode: bindResult))
        }
        bindResult = sqlite3Helper.bindInt(sqlStmtPtr: sqlStmtPtr, index: 2, value: givenActionDeltaValue)
        guard bindResult == SQLITE_OK else {
            throw Error(with: .bindGivenActionValueError(sqliteErrorCode: bindResult))
        }
        bindResult = sqlite3Helper.bindInt(sqlStmtPtr: sqlStmtPtr, index: 3, value: deltaMask)
        guard bindResult == SQLITE_OK else {
            throw Error(with: .bindDeltaMaskError(sqliteErrorCode: bindResult))
        }
        bindResult = sqlite3Helper.bindInt(sqlStmtPtr: sqlStmtPtr, index: 4, value: updateLabelDeltaValue)
        guard bindResult == SQLITE_OK else {
            throw Error(with: .bindUpdateLabelValueError(sqliteErrorCode: bindResult))
        }

        provideIdentificationEntries(for: action, sqlStmtPtr: sqlStmtPtr, onNextValue: onNextValue)
        sqlite3Helper.finalize(sqlStmtPtr: sqlStmtPtr)
    }

    func provideIncrementalBlockingEntries(diffId: Int, for action: Action, onNextValue: (CXCallDirectoryPhoneNumber) -> Void) throws {
        try sqlite3Helper.exec(sqlStmt: "PRAGMA journal_mode = MEMORY")
        let sqlStmtPtr = try { () -> OpaquePointer in
            switch action {
            case .remove:
                // NOTE: This is a workaround for WHOS-654.
                // TODO: Discussing on DB schema revision, if needed.
                return try sqlite3Helper.prepare(sqlStmt: """
                        SELECT id, number, type FROM CallerInfo
                        WHERE ((delta & ?) = ? OR (delta & ?) = ?)
                        ORDER BY id ASC
                        """)
            case .add:
                let sqlStmtPtr = try sqlite3Helper.prepare(sqlStmt: """
                    SELECT id, number, type FROM CallerInfo
                    WHERE ((delta & ?) = ? OR (delta & ?) = ?)
                    AND (type & ?) = ?
                    ORDER BY id ASC
                    """)
                let typeMask = CallerType.topSpam.rawValue
                let topSpamValue = CallerType.topSpam.rawValue
                var bindResult = sqlite3Helper.bindInt(sqlStmtPtr: sqlStmtPtr, index: 5, value: typeMask)
                guard bindResult == SQLITE_OK else {
                    throw Error(with: .bindTypeMaskError(sqliteErrorCode: bindResult))
                }
                bindResult = sqlite3Helper.bindInt(sqlStmtPtr: sqlStmtPtr, index: 6, value: topSpamValue)
                guard bindResult == SQLITE_OK else {
                    throw Error(with: .bindTopSpamValueError(sqliteErrorCode: bindResult))
                }
                return sqlStmtPtr
            }
        }()

        let deltaMask = Delta.updateLabel.rawValue << (2 * diffId)
        var givenActionDeltaValue = Delta.noAction.rawValue // to determine add or remove
        switch action {
        case .add:
            givenActionDeltaValue = Delta.add.rawValue << (2 * diffId)
        case .remove:
            givenActionDeltaValue = Delta.remove.rawValue << (2 * diffId)
        }
        let updateLabelDeltaValue = Delta.updateLabel.rawValue << (2 * diffId)

        var bindResult = sqlite3Helper.bindInt(sqlStmtPtr: sqlStmtPtr, index: 1, value: deltaMask)
        guard bindResult == SQLITE_OK else {
            throw Error(with: .bindDeltaMaskError(sqliteErrorCode: bindResult))
        }
        bindResult = sqlite3Helper.bindInt(sqlStmtPtr: sqlStmtPtr, index: 2, value: givenActionDeltaValue)
        guard bindResult == SQLITE_OK else {
            throw Error(with: .bindGivenActionValueError(sqliteErrorCode: bindResult))
        }
        bindResult = sqlite3Helper.bindInt(sqlStmtPtr: sqlStmtPtr, index: 3, value: deltaMask)
        guard bindResult == SQLITE_OK else {
            throw Error(with: .bindDeltaMaskError(sqliteErrorCode: bindResult))
        }
        bindResult = sqlite3Helper.bindInt(sqlStmtPtr: sqlStmtPtr, index: 4, value: updateLabelDeltaValue)
        guard bindResult == SQLITE_OK else {
            throw Error(with: .bindUpdateLabelValueError(sqliteErrorCode: bindResult))
        }

        provideBlockingEntries(sqlStmtPtr: sqlStmtPtr, onNextValue: onNextValue)
        sqlite3Helper.finalize(sqlStmtPtr: sqlStmtPtr)
    }

    private func getLabelPrefixBy(type: CallerType) -> String {
        if type.contains(CallerType.card) {
            return "✅"
        } else if type.contains(CallerType.topSpam) || type.contains(CallerType.spam) || type.contains(CallerType.singaporePoliceForce) {
            return "⚠️"
        } else {
            return ""
        }
    }

    private func provideIdentificationEntries(for action: Action,
                                              sqlStmtPtr: OpaquePointer,
                                              onNextValue: (CallerInfo) -> Void) {
        while sqlite3Helper.step(sqlStmtPtr: sqlStmtPtr) == SQLITE_ROW {
            autoreleasepool {
                let id = Int(sqlite3Helper.columnInt32(sqlStmtPtr: sqlStmtPtr, colNum: 0))
                var tmpNumber = sqlite3Helper.columnInt64(sqlStmtPtr: sqlStmtPtr, colNum: 1).littleEndian
                let numberData = revolver.decrypt(data: Data(bytes: &tmpNumber, count: MemoryLayout.size(ofValue: tmpNumber)), iv: id)
                let number = numberData.withUnsafeBytes({ bufferRawPointer -> CXCallDirectoryPhoneNumber in
                    return bufferRawPointer.load(as: CXCallDirectoryPhoneNumber.self)
                })
                let type = CallerType(rawValue: sqlite3Helper.columnInt32(sqlStmtPtr: sqlStmtPtr, colNum: 2))

                let blobData = sqlite3Helper.columnBLOB(sqlStmtPtr: sqlStmtPtr, colNum: 3)
                if !blobData.isEmpty {
                    let labelData = revolver.decrypt(data: blobData, iv: id)

                    if let label = String(data: labelData, encoding: .utf8), number > 0 {
                        autoreleasepool {
                            // boundary condition: giving 0 to call directory extension,
                            // there won't be any error before the extension ends. However,
                            // the containing app will receives call directory manager error 4
                            // (duplicate number). If offline DB contains 0 in it,
                            // loading number will always fail.
                            onNextValue(CallerInfo(number: number, name: label, type: type))
                        }
                    } else {
                        // if can't get label, do nothing.
                    }
                } else {
                    // For the numbers to be deleted during incremental mode, their names are empty string
                    if action == .remove {
                        onNextValue(CallerInfo(number: number, name: ""))
                    } else {
                        // simply skip
//                        logger.warn("A number to be added has no label.")
//                        logger.debug("A number to be added has no label: \(number)")
                    }
                }
            }
        }
    }

    private func provideBlockingEntries(sqlStmtPtr: OpaquePointer,
                                        onNextValue: (CXCallDirectoryPhoneNumber) -> Void) {
        while sqlite3Helper.step(sqlStmtPtr: sqlStmtPtr) == SQLITE_ROW {
            autoreleasepool {
                let id = Int(sqlite3Helper.columnInt32(sqlStmtPtr: sqlStmtPtr, colNum: 0))
                var tmpNumber = sqlite3Helper.columnInt64(sqlStmtPtr: sqlStmtPtr, colNum: 1).littleEndian
                let numberData = revolver.decrypt(data: Data(bytes: &tmpNumber, count: MemoryLayout.size(ofValue: tmpNumber)), iv: id)
                let number = numberData.withUnsafeBytes({ bufferRawPointer -> CXCallDirectoryPhoneNumber in
                    return bufferRawPointer.load(as: CXCallDirectoryPhoneNumber.self)
                })

                // boundary condition: giving 0 to call directory extension,
                // there won't be any error before the extension ends. However,
                // the containing app will receives call directory manager error 4
                // (duplicate number). If offline DB contains 0 in it,
                // loading number will always fail.
                if number > 0 {
                    autoreleasepool {
                        onNextValue(number)
                    }
                }
            }
        }
    }
}
