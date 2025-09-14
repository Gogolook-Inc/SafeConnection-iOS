//
//  CompressionCodec.swift
//  Kirin
//
//  Created by Dong-Yi Wu on 2019/5/2.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import Compression
import Foundation

/// An object providing compression and decompression of a set of data compression algorithms
public class CompressionCodec {
    
    // MARK: Public properties / enums
    
    /// Algorithms that CompressionCodec supports
    ///
    /// - lz4: LZ4
    /// - zlib: zlib
    /// - lzma: LZMA
    /// - lz4Raw: LZ4_RAW (No supported)
    /// - lzfse: Apple-specific encoders
    public enum Algorithm: CustomStringConvertible {
        case lz4
        case zlib
        case lzma
//        case lz4Raw   // NOTE: so far initing stream lz4_raw always fails. Not supported.
        case lzfse
        
        public var description: String {
            switch self {
            case .lz4:
                return "lz4"
            case .zlib:
                return "zlib"
            case .lzma:
                return "lzma"
            case .lzfse:
                return "lzfse"
            }
        }
        
        // MARK: File private properties
        
        fileprivate var _algorithm: compression_algorithm {
            switch self {
            case .lz4:
                return COMPRESSION_LZ4
            case .zlib:
                return COMPRESSION_ZLIB
            case .lzma:
                return COMPRESSION_LZMA
            case .lzfse:
                return COMPRESSION_LZFSE
            }
        }
    }

    public let algorithm: Algorithm
    
    // MARK: Private properties / types
    
    private let bufferSize: Int

    // MARK: Public methods
    
    /// Initializer
    ///
    /// - Parameters:
    ///   - algorithm: the algorithm that the instantiated object uses
    ///   - bufferSize: the buffer size that the instance uses for compression operations (in bytes)
    public init(_ algorithm: Algorithm, bufferSize: Int) {
        self.algorithm = algorithm
        self.bufferSize = bufferSize
    }
    
    /// Compress a file
    ///
    /// - Parameters:
    ///   - srcURL: source file URL
    ///   - dstURL: output URL
    ///   - progressClosure: the closure receives bytes processed
    /// - Throws:  the error that failed the operation
    public func compress(srcURL: URL, dstURL: URL, progressClosure: (Int64) -> Void) throws {
        try compression(operation: COMPRESSION_STREAM_ENCODE,
                        srcURL: srcURL,
                        dstURL: dstURL,
                        progressClosure: progressClosure)
    }
    
    /// Decompress a file
    ///
    /// - Parameters:
    ///   - srcURL: source file URL
    ///   - dstURL: output URL
    ///   - progressClosure: the closure receives bytes processed
    /// - Throws: the error that failed the operation
    public func decompress(srcURL: URL, dstURL: URL, progressClosure: (Int64) -> Void) throws {
        try compression(operation: COMPRESSION_STREAM_DECODE,
                        srcURL: srcURL,
                        dstURL: dstURL,
                        progressClosure: progressClosure)
    }
    
    // MARK: Private methods
    // swiftlint:disable:next cyclomatic_complexity function_body_length superfluous_disable_command
    private func compression(operation: compression_stream_operation,
                             srcURL: URL,
                             dstURL: URL,
                             progressClosure: (Int64) -> Void) throws {
        let dstBufferPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer {
            dstBufferPtr.deallocate()
        }
        
        // Instantiate and initialize a compression stream
        let streamPtr = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1)
        defer {
            streamPtr.deallocate()
        }
        
        var stream = streamPtr.pointee
        let compressionInitStatus = compression_stream_init(&stream, operation, algorithm._algorithm)
        guard compressionInitStatus != COMPRESSION_STATUS_ERROR else {
            throw Error(with: .failedInitCompressionStream)
        }
        defer {
            compression_stream_destroy(&stream)
        }
        
        // Setup compression stream after initialization
        // This MUST be done AFTER compression stream initialization, as the initialization zeroes all fields in stream
        stream.src_size = 0     // 0 as there is no data in source buffer so far
        stream.dst_ptr = dstBufferPtr
        stream.dst_size = bufferSize
        
        // Open source file
        let srcFileHandle: FileHandle = try {
            do {
                return try FileHandle(forReadingFrom: srcURL)
            } catch {
                throw Error(with: .failedOpenSrcFile, underlyingError: error)
            }
            }()
        defer {
            srcFileHandle.closeFile()
        }
        
        // Create and open destination file
        guard !FileManager.default.fileExists(atPath: dstURL.path) else {
            throw Error(with: .dstFileAlreadyExists)
        }
        
        guard FileManager.default.createFile(atPath: dstURL.path,
                                             contents: nil,
                                             attributes: nil) == true else {
                                                throw Error(with: .failedCreateDstFile)
        }
        let dstFileHandle: FileHandle = try {
            do {
                return try FileHandle(forWritingTo: dstURL)
            } catch {
                throw Error(with: .failedOpenSrcFile, underlyingError: error)
            }
            }()
        defer {
            dstFileHandle.closeFile()
        }
        
        var srcData: Data?
        var shouldContinue = true
        repeat {
            try autoreleasepool {
                var flags = Int32(0)
                
                // If this iteration has consumed all of the source data,
                // read a new tempData buffer from the input file.
                if stream.src_size == 0 {
                    srcData = srcFileHandle.readData(ofLength: bufferSize)
                    stream.src_size = srcData!.count
                    if srcData!.count < bufferSize {
                        flags = Int32(COMPRESSION_STREAM_FINALIZE.rawValue)
                    }
                }
                
                // Perform compression or decompression.
                if let srcData = srcData {
                    // swiftlint:disable:next unneeded_parentheses_in_closure_argument
                    guard let compressionStatus = srcData.withUnsafeBytes({ (bufferRawPointer) -> compression_status? in
                        if let pointer = bufferRawPointer.bindMemory(to: UInt8.self).baseAddress {
                            stream.src_ptr = pointer.advanced(by: srcData.count - stream.src_size)
                            let status = compression_stream_process(&stream, flags)
                            return status
                        } else {
                            return nil
                        }
                    }) else {
                        assertionFailure("Unexpected")
                        return
                    }
                    
                    switch compressionStatus {
                    case COMPRESSION_STATUS_OK,
                         COMPRESSION_STATUS_END:
                        // Get the number of bytes put in the destination buffer. This is the difference between
                        // stream.dst_size before the call (here bufferSize), and stream.dst_size after the call.
                        let count = bufferSize - stream.dst_size
                        
                        let outputData = Data(bytesNoCopy: dstBufferPtr,
                                              count: count,
                                              deallocator: .none)
                        
                        // Write all produced bytes to the output file.
                        dstFileHandle.write(outputData)
                        
                        // Reset the stream to receive the next batch of output.
                        stream.dst_ptr = dstBufferPtr
                        stream.dst_size = bufferSize
                        progressClosure(Int64(srcFileHandle.offsetInFile))
                        
                        shouldContinue = compressionStatus == COMPRESSION_STATUS_OK
                    case COMPRESSION_STATUS_ERROR:
                        throw operation == COMPRESSION_STREAM_ENCODE ? Error(with: .failedCompression) : Error(with: .failedDecompression)
                    default:
                        assertionFailure("Unexpected")
                    }   // end switch
                }   // end if let srcData = srcData
            }   // end autoreleasepool
        } while shouldContinue
    }
}
