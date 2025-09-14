//
//  Revolver+Error.swift
//  Kirin
//
//  Created by Dong-Yi Wu on 2019/10/18.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import Foundation

public extension Revolver {
    struct Error: Swift.Error {
        public enum ErrorEnum: Int {
            case invalidEncryptionKey = -1
        }
        
        public let underlyingError: Swift.Error?
        public let errorEnum: ErrorEnum
        
        public init(with errorEnum: Error.ErrorEnum, underlyingError: Swift.Error? = nil) {
            self.errorEnum = errorEnum
            self.underlyingError = underlyingError
        }
        
        public var localizedDescription: String {
            switch errorEnum {
            case .invalidEncryptionKey:
                return "Invalid encryption key"
            }
        }
    }
}

extension Revolver.Error: CustomNSError {
    public static var errorDomain = "com.gogolook.wcsdk.revolver.error"
    public var errorCode: Int { errorEnum.rawValue }
}
