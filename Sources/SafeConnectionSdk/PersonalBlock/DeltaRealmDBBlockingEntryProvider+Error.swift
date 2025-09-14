//
//  DeltaRealmDBBlockingEntryProvider+Error.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/6/4.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import Foundation

extension DeltaRealmDBBlockingEntryProvider {
    struct Error: WSCError {
        typealias InternalErrorEnum = ErrorEnum

        static let errorDomain = "com.starhub.scambuster.deltarealmdbblockingentryprovider.error"

        enum ErrorEnum: LocalizedError {
            case invalidCipherKey

            var errorDescription: String? {
                switch self {
                case .invalidCipherKey:
                    return "Invlaid cipher key. the key must be 64-byte long"
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
            case .invalidCipherKey:
                return -1
            }
        }

        var errorUserInfo: [String: Any] {
            var info = internalUserInfo

            info[NSLocalizedDescriptionKey] = errorEnum.localizedDescription
            return info
        }
    }
}
