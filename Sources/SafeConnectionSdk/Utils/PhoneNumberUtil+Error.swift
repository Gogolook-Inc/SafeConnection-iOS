//
//  PhoneNumberUtil+Error.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/5/17.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import Foundation

extension PhoneNumberUtil {
    struct Error: WSCError {
        typealias InternalErrorEnum = ErrorEnum

        static let errorDomain = "com.gogolook.oem-sdk.phonenumberutil.error"

        enum ErrorEnum: LocalizedError {
            case invalidInitParam

            var errorDescription: String? {
                switch self {
                case .invalidInitParam:
                    return "Invalid parameter: number is empty"
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
            case .invalidInitParam:
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
