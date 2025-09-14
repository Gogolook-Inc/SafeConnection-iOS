//
//  NonceGenerator.swift
//  Auth
//
//  Created by Nixon Shih on 2025/3/7.
//

import CryptoKit
import Foundation

/// A generator to generate a nonce value
/// - See:  [Nonce Mechanism](https://gogolook.atlassian.net/wiki/spaces/WB/pages/12353615/Auth+API#Nonce-Mechanism)
public class NonceGenerator {
    public init() {}

    public func generateNonce<T>(from parameters: [T: String]) throws -> String where T: RawRepresentable<String> {
        try parameters
            .reduce(into: [(String, String)]()) {
                $0.append(($1.key.rawValue, $1.value))
            }
            .sorted { $0.0 < $1.0 }
            .map { "\($0.0)=\($0.1)" }
            .joined(separator: "&")
            .sha256Hash()
    }
}
