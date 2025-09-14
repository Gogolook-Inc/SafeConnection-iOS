//
//  DeltaSQLiteDBEntryProvider+Error.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/5/17.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import Foundation

extension DeltaSQLiteDBEntryProvider {
    struct Error: WSCError {
        typealias InternalErrorEnum = ErrorEnum

        static let errorDomain = "com.starhub.scambuster.deltasqlitedbloader.error"

        enum ErrorEnum: LocalizedError {
            case bindDeltaMaskError(sqliteErrorCode: Int32)
            case bindTypeMaskError(sqliteErrorCode: Int32)
            case bindGivenActionValueError(sqliteErrorCode: Int32)
            case bindUpdateLabelValueError(sqliteErrorCode: Int32)
            case bindTopSpamValueError(sqliteErrorCode: Int32)

            var errorDescription: String? {
                switch self {
                case .bindDeltaMaskError(let sqliteErrorCode):
                    return "Binding delta mask failed. SQLite error code: \(sqliteErrorCode)"
                case .bindTypeMaskError(let sqliteErrorCode):
                    return "Binding type mask failed. SQLite error code: \(sqliteErrorCode)"
                case .bindGivenActionValueError(let sqliteErrorCode):
                    return "Binding a given action(add or remove) value failed. SQLite error code: \(sqliteErrorCode)"
                case .bindUpdateLabelValueError(let sqliteErrorCode):
                    return "Binding update label value failed. SQLite error code: \(sqliteErrorCode)"
                case .bindTopSpamValueError(let sqliteErrorCode):
                    return "Binding top spam value failed. SQLite error code: \(sqliteErrorCode)"
                }
            }
        }

        let underlyingError: Swift.Error?
        let errorEnum: ErrorEnum
        let commonErrorInfo: WSCCommonErrorInfo?

        init(
            with errorEnum: Error.ErrorEnum,
            underlyingError: Swift.Error? = nil,
            file: String = (#file as NSString).lastPathComponent,
            function: String = #function,
            line: Int = #line
        ) {
            self.errorEnum = errorEnum
            self.commonErrorInfo = WSCCommonErrorInfo(file: file, function: function, line: line)
            self.underlyingError = underlyingError
        }

        var errorDescription: String? {
            return errorEnum.localizedDescription
        }

        var errorCode: Int {
            switch errorEnum {
            case .bindDeltaMaskError:
                return -1001
            case .bindTypeMaskError:
                return -1002
            case .bindGivenActionValueError:
                return -1003
            case .bindUpdateLabelValueError:
                return -1004
            case .bindTopSpamValueError:
                return -1005
            }
        }

        var errorUserInfo: [String: Any] {
            var info = internalUserInfo

            info[NSLocalizedDescriptionKey] = errorEnum.localizedDescription
            return info
        }
    }
}
