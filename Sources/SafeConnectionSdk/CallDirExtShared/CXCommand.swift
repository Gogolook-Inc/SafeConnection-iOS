//
//  CXCommand.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/5/13.
//  Copyright © 2019 Gogolook. All rights reserved.
//
import CallKit

/// This protocol defines a CXCommand, namely "call directory extension command". A command provides a method `execute()` to perform the action defined by the command.
protocol CXCommand {
    func execute() throws -> CXCmdResult
}

/// This structure denotes the result of the execution of a command
public struct CXCmdResult: Codable, CustomStringConvertible {
    let commandTypeId: CXCmdTypeIdentifier
    let isSuceeded: Bool
    let errorMessage: String?

    private enum CodingKeys: String, CodingKey {
        case commandTypeId = "commandTypeId",
        isSuceeded = "isSucceeded",
        errorMessage = "errorMessage"
    }

    /// Constructor
    ///
    /// - Parameters:
    ///   - commandTypeId: the type of the command
    ///   - isSucceeded: whether the command finished successfully
    ///   - errorMessage: the error message gotten when the command fails
    init(commandTypeId: CXCmdTypeIdentifier, isSucceeded: Bool, errorMessage: String?) {
        self.commandTypeId = commandTypeId
        self.isSuceeded = isSucceeded
        self.errorMessage = errorMessage
    }

    // MARK: Codable

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(commandTypeId.rawValue, forKey: .commandTypeId)
        try container.encode(isSuceeded, forKey: .isSuceeded)
        try container.encodeIfPresent(errorMessage, forKey: .errorMessage)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let commandRawValue = try container.decode(Int.self, forKey: .commandTypeId)
        guard let commandTypeId = CXCmdTypeIdentifier(rawValue: commandRawValue) else {
            throw Error(with: .invalidCommandType(value: commandRawValue))
        }
        self.commandTypeId = commandTypeId
        isSuceeded = try container.decode(Bool.self, forKey: .isSuceeded)
        errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
    }

    // MARK: CustomStringConvertible

    public var description: String {
        return "\(commandTypeId) \(isSuceeded ? "succeeded" : "failed"). Error: \(errorMessage ?? "no error")"
    }
}

extension CXCmdResult: Equatable {}

/// This enumeration to used to indicate the type of a commmand as an integer value
///
/// - loadCompleteEntrySet: loading complete set of call directory entries. This is the default command of a call directory extension.
/// - loadIncrementalEntrySet: loading incremental set of call directory entries.
/// - doNothing: do nothing. This is used to enable a call directory extension without loading call directory entries
/// - removeAllIdentificationEntries: remove all identification entries of a call directory extension
/// - removeAllBlockingEntries: remove all blocking entries of a call directory extension
enum CXCmdTypeIdentifier: Int, CustomStringConvertible {
    case loadCompleteEntrySet = 0  // default command for a call directory extension
    case loadIncrementalEntrySet
    case loadTopSpammersIncrementally // to incrementally block top spammers (offline DB CX only)
    case unloadTopSpammersIncrementally   // to incrementally unblock top spammers (offline DB CX only)

    // the commands for debugging or testing
    case doNothing
    case removeAllIdentificationEntries
    case removeAllBlockingEntries

    var description: String {
        switch self {
        case .loadCompleteEntrySet:
            return "CMD Load complete entry set"
        case .loadIncrementalEntrySet:
            return "CMD Load incremental entry set"
        case .loadTopSpammersIncrementally:
            return "CMD Load top spammers incrementally"
        case .unloadTopSpammersIncrementally:
            return "CMD Unload top spammers incrementally"
        case .doNothing:
            return "CMD Do nothing"
        case .removeAllIdentificationEntries:
            return "CMD remove all identification entries"
        case .removeAllBlockingEntries:
            return "CMD remove all blocking entries"
        }
    }
}
