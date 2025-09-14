//
//  GGLError.swift
//  melman
//
//  Created by Luis Wu on 25/08/2017.
//  Copyright © 2017 Gogolook. All rights reserved.
//

import Foundation

protocol WSCError: CustomNSError, LocalizedError {
    associatedtype InternalErrorEnum: Error

    var rootCause: Error { get }
    var underlyingError: Error? { get }
    var errorEnum: InternalErrorEnum { get }
    var commonErrorInfo: WSCCommonErrorInfo? { get }

    init(with errorEnum: InternalErrorEnum, underlyingError: Error?, file: String, function: String, line: Int)
}
