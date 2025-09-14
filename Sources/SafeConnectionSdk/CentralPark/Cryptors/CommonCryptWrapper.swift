//
//  CommonCryptWrapper.swift
//  melman
//
//  Created by Luis Wu on 25/01/2018.
//  Copyright © 2018 Gogolook. All rights reserved.
//

import CommonCrypto
import Foundation

extension CCCryptorStatus {
    func toCryptorOpResultStatus() -> Cryptor.OperationResult.Status {
        switch Int(self) {
        case kCCSuccess: return .success
        case kCCParamError: return .paramError
        case kCCBufferTooSmall: return .bufferTooSmall
        case kCCMemoryFailure: return .memoryFailure
        case kCCAlignmentError: return .alignmentError
        case kCCDecodeError: return .decodeError
        case kCCUnimplemented: return .unimplemented
        case kCCOverflow: return .overflow
        case kCCRNGFailure: return .rngFailure
        case kCCUnspecifiedError: return .unspecifiedError
        case kCCCallSequenceError: return .callSequenceError
        case kCCKeySizeError: return .keySizeError

        default:
            assertionFailure("Got undefined status, rawValue: \(self)")
            return .unspecifiedError
        }
    }
}

public class Cryptor {
    public struct OperationResult {
        public enum Status {
            case success
            case paramError
            case bufferTooSmall
            case memoryFailure
            case alignmentError
            case decodeError
            case unimplemented
            case overflow
            case rngFailure
            case unspecifiedError
            case callSequenceError
            case keySizeError
        }

        public let data: Data
        public let status: Status

        public init(status: Status, data: Data) {
            self.status = status
            self.data = data
        }
    }

    public enum Algorithm: CCAlgorithm, CustomStringConvertible {
        case aes128, des, tripleDES, cast, rc4, rc2, blowfish

        public var description: String {
            switch self {
            case .aes128: return "AES128"
            case .des: return "DES"
            case .tripleDES: return "3DES"
            case .cast: return "CAST"
            case .rc4: return "RC4"
            case .rc2: return "RC2"
            case .blowfish: return "Blowfish"
            }
        }

        public var rawValue: CCAlgorithm {
            switch self {
            case .aes128: return CCAlgorithm(kCCAlgorithmAES128)
            case .des: return CCAlgorithm(kCCAlgorithmDES)
            case .tripleDES: return CCAlgorithm(kCCAlgorithm3DES)
            case .cast: return CCAlgorithm(kCCAlgorithmCAST)
            case .rc4: return CCAlgorithm(kCCAlgorithmRC4)
            case .rc2: return CCAlgorithm(kCCAlgorithmRC2)
            case .blowfish: return CCAlgorithm(kCCAlgorithmBlowfish)
            }
        }

        public var blockSize: Int {
            switch self {
            case .aes128: return Int(kCCBlockSizeAES128)
            case .des: return Int(kCCBlockSizeDES)
            case .tripleDES: return Int(kCCBlockSize3DES)
            case .cast: return Int(kCCBlockSizeCAST)
            case .rc4: return 0 // RC4 is not a block cipher but a stream cipher.
            case .rc2: return Int(kCCBlockSizeRC2)
            case .blowfish: return Int(kCCBlockSizeBlowfish)
            }
        }
    }

    public enum KeySize {
        case aes128, aes192, aes256, des, tripleDES, minCAST, maxCAST, minRC2, maxRC2, minRC4, maxRC4, minBlowfish, maxBlowfish

        var rawValue: Int {
            switch self {
            case .aes128: return Int(kCCKeySizeAES128)
            case .aes192: return Int(kCCKeySizeAES192)
            case .aes256: return Int(kCCKeySizeAES256)
            case .des: return Int(kCCKeySizeDES)
            case .tripleDES: return Int(kCCKeySize3DES)
            case .minCAST: return Int(kCCKeySizeMinCAST)
            case .maxCAST: return Int(kCCKeySizeMaxCAST)
            case .minRC2: return Int(kCCKeySizeMinRC2)
            case .maxRC2: return Int(kCCKeySizeMaxRC2)
            case .minRC4: return Int(kCCKeySizeMinRC4)
            case .maxRC4: return Int(kCCKeySizeMaxRC4)
            case .minBlowfish: return Int(kCCKeySizeMinBlowfish)
            case .maxBlowfish: return Int(kCCKeySizeMaxBlowfish)
            }
        }
    }

    public struct Options: OptionSet {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        func toCCOptions() -> CCOptions {
            return CCOptions(self.rawValue)
        }

        public static let pkcs7Padding = Options(rawValue: 0x1)
        public static let ecbMode = Options(rawValue: 0x1 << 1)   // CBC = not setting this flag
    }

    private enum Operation: CCOperation {
        case encrypt, decrypt

        var rawValue: CCOperation {
            switch self {
            case .encrypt: return CCOperation(kCCEncrypt)
            case .decrypt: return CCOperation(kCCDecrypt)
            }
        }
    }

    public static func decrypt(algorithm: Algorithm, options: Options, key: Data, iv: Data, ciphertext: Data) -> OperationResult {
        return cryptoOperation(.decrypt, algorithm: algorithm, options: options, key: key, iv: iv, input: ciphertext)
    }
    public static func encrypt(algorithm: Algorithm, options: Options, key: Data, iv: Data, plaintext: Data) -> OperationResult {
        return cryptoOperation(.encrypt, algorithm: algorithm, options: options, key: key, iv: iv, input: plaintext)
    }

    // swiftlint:disable:next function_parameter_count
    private static func cryptoOperation(_ operation: Operation, algorithm: Algorithm, options: Options, key: Data, iv: Data, input: Data) -> OperationResult {
        assert(isValidKeyLength(key: key, algorithm: algorithm), "invalid key length: \(key.count) for \(algorithm)")
        let inputDataLength = input.count + algorithm.blockSize
        var outputData = Data(count: inputDataLength)

        var numberBytesProcessed: Int = 0

        let status = outputData.withUnsafeMutableBytes { outputRawBufferPtr -> CCCryptorStatus in
            return input.withUnsafeBytes({ inputRawBufferPtr -> CCCryptorStatus in
                return key.withUnsafeBytes({ keyRawBufferPtr -> CCCryptorStatus in
                    return iv.withUnsafeBytes({ ivRawBufferPtr -> CCCryptorStatus in
                        return CCCrypt(operation.rawValue,
                                       algorithm.rawValue,
                                       options.toCCOptions(),
                                       keyRawBufferPtr.baseAddress,
                                       keyRawBufferPtr.count,
                                       ivRawBufferPtr.baseAddress,
                                       inputRawBufferPtr.baseAddress,
                                       inputRawBufferPtr.count,
                                       outputRawBufferPtr.baseAddress,
                                       outputRawBufferPtr.count,
                                       &numberBytesProcessed
                        )
                    })
                })
            })
        }

        if status.toCryptorOpResultStatus() == .success {
            outputData.removeSubrange(numberBytesProcessed..<outputData.count)
        } else {
            outputData.removeAll()
        }

        return OperationResult(status: status.toCryptorOpResultStatus(), data: outputData)
    }

    private static func isValidKeyLength(key: Data, algorithm: Algorithm) -> Bool {
        let keyLength = key.count
        switch algorithm {
        case .aes128:
            return keyLength == KeySize.aes128.rawValue || keyLength == KeySize.aes192.rawValue || keyLength == KeySize.aes256.rawValue
        case .des:
            return keyLength == KeySize.des.rawValue
        case .tripleDES:
            return keyLength == KeySize.tripleDES.rawValue
        case .cast:
            return keyLength >= KeySize.minCAST.rawValue && keyLength <= KeySize.maxCAST.rawValue
        case .rc4:
            return keyLength >= KeySize.minRC4.rawValue && keyLength <= KeySize.maxRC4.rawValue
        case .rc2:
            return keyLength >= KeySize.minRC2.rawValue && keyLength <= KeySize.maxRC2.rawValue
        case .blowfish:
            return keyLength >= KeySize.minBlowfish.rawValue && keyLength <= KeySize.maxBlowfish.rawValue
        }
    }
}

public class SHA {
    private let algorithm: Algorithm
    typealias Byte = UInt8
    typealias DigestImplementation = (UnsafeRawPointer?, CC_LONG, UnsafeMutablePointer<Byte>?) -> UnsafeMutablePointer<Byte>?

    public enum Algorithm: CustomStringConvertible {
        case sha1, sha224, sha256, sha384, sha512

        public var description: String {
            switch self {
            case .sha1: return "SHA1"
            case .sha224: return "SHA224"
            case .sha256: return "SHA256"
            case .sha384: return "SHA384"
            case .sha512: return "SHA512"
            }
        }

        public var digestLength: Int {
            switch self {
            case .sha1: return Int(CC_SHA1_DIGEST_LENGTH)
            case .sha224: return Int(CC_SHA224_DIGEST_LENGTH)
            case .sha256: return Int(CC_SHA256_DIGEST_LENGTH)
            case .sha384: return Int(CC_SHA384_DIGEST_LENGTH)
            case .sha512: return Int(CC_SHA512_DIGEST_LENGTH)
            }
        }

        var digest: DigestImplementation {
            switch self {
            case .sha1: return CC_SHA1
            case .sha224: return CC_SHA224
            case .sha256: return CC_SHA256
            case .sha384: return CC_SHA384
            case .sha512: return CC_SHA512
            }
        }
    }

    public init(algorithm: Algorithm) {
        self.algorithm = algorithm
    }

    public func digest(message: Data) -> Data {
        var digest = [Byte](repeatElement(0, count: algorithm.digestLength))
        message.withUnsafeBytes { _ = algorithm.digest($0.baseAddress, CC_LONG($0.count), &digest) }

        return Data(digest)
    }
}

public class HMAC {
    typealias Byte = UInt8
    public enum Algorithm: CustomStringConvertible {
        case md5, sha1, sha224, sha256, sha384, sha512

        public var description: String {
            switch self {
            case .md5: return "HMAC-MD5"
            case .sha1: return "HMAC-SHA1"
            case .sha224: return "HMAC-SHA224"
            case .sha256: return "HMAC-SHA256"
            case .sha384: return "HMAC-SHA384"
            case .sha512: return "HMAC-SHA512"
            }
        }

        public var ccHMACAlgorithm: CCHmacAlgorithm {
            switch self {
            case .md5: return CCHmacAlgorithm(kCCHmacAlgMD5)
            case .sha1: return CCHmacAlgorithm(kCCHmacAlgSHA1)
            case .sha224: return CCHmacAlgorithm(kCCHmacAlgSHA224)
            case .sha256: return CCHmacAlgorithm(kCCHmacAlgSHA256)
            case .sha384: return CCHmacAlgorithm(kCCHmacAlgSHA384)
            case .sha512: return CCHmacAlgorithm(kCCHmacAlgSHA512)
            }
        }

        fileprivate var digestLength: Int {
            switch self {
            case .md5: return Int(CC_MD5_DIGEST_LENGTH)
            case .sha1: return Int(CC_SHA1_DIGEST_LENGTH)
            case .sha224: return Int(CC_SHA224_DIGEST_LENGTH)
            case .sha256: return Int(CC_SHA256_DIGEST_LENGTH)
            case .sha384: return Int(CC_SHA384_DIGEST_LENGTH)
            case .sha512: return Int(CC_SHA512_DIGEST_LENGTH)
            }
        }
    }

    public let algorithm: Algorithm

    public init(algorithm: Algorithm) {
        self.algorithm = algorithm
    }

    public func hash(message: Data, key: Data) -> Data {
        var result = [Byte](repeatElement(0, count: algorithm.digestLength))
        message.withUnsafeBytes { messageRawBufferPtr in
            key.withUnsafeBytes({ keyRawBufferPtr in
                CCHmac(algorithm.ccHMACAlgorithm, keyRawBufferPtr.baseAddress, keyRawBufferPtr.count, messageRawBufferPtr.baseAddress, messageRawBufferPtr.count, &result)
            })
        }

        return Data(result)
    }
}

// NOTE: We may leverage it to compose extensions replacing NSString+NSHash pod
public class MD5 {
    typealias Byte = UInt8

    public static func hash(message: Data) -> Data {
        var result = [Byte](repeatElement(0, count: Int(CC_MD5_DIGEST_LENGTH)))
        message.withUnsafeBytes { messageRawBufferPtr in
            _ = CC_MD5(messageRawBufferPtr.baseAddress, CC_LONG(messageRawBufferPtr.count), &result)
        }
        return Data(result)
    }
}
