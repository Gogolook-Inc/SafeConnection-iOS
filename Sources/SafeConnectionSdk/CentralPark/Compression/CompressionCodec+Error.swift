//
//  CompressionCodec+Error.swift
//  Kirin
//
//  Created by Dong-Yi Wu on 2019/5/17.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import Foundation

public extension CompressionCodec {
    struct Error: Swift.Error {
        public enum ErrorEnum: Int {
            case failedInitCompressionStream = -1
            case failedOpenSrcFile = -1001
            case failedOpenDstFile = -1002
            case failedCreateDstFile = -1003
            case dstFileAlreadyExists = -1004
            case failedCompression = -2001
            case failedDecompression = -2002
        }
        
        let underlyingError: Swift.Error?
        let errorEnum: ErrorEnum
        
        public init(with errorEnum: Error.ErrorEnum, underlyingError: Swift.Error? = nil) {
            self.errorEnum = errorEnum
            self.underlyingError = underlyingError
        }
        
        public var localizedDescription: String {
            let description: String
            
            switch errorEnum {
            case .failedInitCompressionStream:
                description = "Failed to initialize a compression stream"
            case .failedOpenSrcFile:
                description = "Failed to open source file"
            case .failedOpenDstFile:
                description = "Failed to open destination file"
            case .failedCreateDstFile:
                description = "Failed to create destination file"
            case .dstFileAlreadyExists:
                description = "Destination file already exists"
            case .failedCompression:
                description = "Failed to compress the file"
            case .failedDecompression:
                description = "Failed to decompress the file"
            }
            
            return (underlyingError == nil)
                ? description
                : description + " \(String(describing: underlyingError))"
        }
    }
}

extension CompressionCodec.Error: CustomNSError {
    public static var errorDomain = "com.gogolook.wcsdk.compression.codec.error"
    public var errorCode: Int { errorEnum.rawValue }
}
