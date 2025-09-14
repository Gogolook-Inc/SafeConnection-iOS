//
//  MessageFilterRuleContainer+Error.swift
//  Kirin
//
//  Created by Darkes Fang on 2020/8/26.
//  Copyright © 2020 Gogolook. All rights reserved.
//

import Foundation

extension MessageFilterRuleContainer {
    struct Error: WSCError {
        typealias InternalErrorEnum = ErrorEnum

        static let errorDomain = "gogolook.whoscall.MessageFilterRuleContainer.error"

        enum ErrorEnum: LocalizedError {
            case invalidFormat
            case invalidRuleType
            case invalidRuleData

            var errorDescription: String? {
                switch self {
                case .invalidFormat:
                    return "Invalid JSON object"
                case .invalidRuleType:
                    return "Invalid rule type"
                case .invalidRuleData:
                    return "Invalid rule data"
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
            case .invalidFormat:
                return -1
            case .invalidRuleType:
                return -2
            case .invalidRuleData:
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
