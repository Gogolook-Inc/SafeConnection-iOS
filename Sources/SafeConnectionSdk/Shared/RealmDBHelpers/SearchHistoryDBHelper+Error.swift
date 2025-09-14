//
//  SearchHistoryDBHelper+Error.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/7/1.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import Foundation

extension SearchHistoryDBHelper {
    struct Error: WSCError {
        typealias InternalErrorEnum = ErrorEnum

        static let errorDomain = "com.starhub.scambuster.searchhistorydbhelper.error"

        enum ErrorEnum: LocalizedError {
            case entryAlreadyExists
            case inputDuplicateE164
            case entryNotFound

            var errorDescription: String? {
                switch self {
                case .entryAlreadyExists:
                    return "Entry already exists"
                case .inputDuplicateE164:
                    return "Duplicate e164 in the input"
                case .entryNotFound:
                    return "Entry not found"
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
            case .entryAlreadyExists:
                return -1
            case .inputDuplicateE164:
                return -2
            case .entryNotFound:
                return -3
            }
        }

        var errorUserInfo: [String: Any] {
            var info = internalUserInfo

            info[NSLocalizedDescriptionKey] = errorEnum.localizedDescription
            return info
        }
    }
}
