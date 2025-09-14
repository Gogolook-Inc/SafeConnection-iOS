//
//  BlockedPhoneNumberInfo+Error.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/5/17.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import Foundation

extension BlockedPhoneNumberInfo {
    struct Error: WSCError {
        typealias InternalErrorEnum = ErrorEnum

        static let errorDomain = "com.gogolook.oem-sdk.model.realm.blockedphonenumberinfo.error"

        enum ErrorEnum: LocalizedError {
            case cannotConvertE164(input: String)

            var errorDescription: String? {
                switch self {
                case .cannotConvertE164(let input):
                    return "Cannot convert \(input) into CXCallDirectoryPhoneNumber"
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
            case .cannotConvertE164:
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
