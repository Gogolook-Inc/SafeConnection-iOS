//
//  PhoneNumberBlocker.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/7/15.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import CallKit

/// The implementation of protocol `PhoneNumberBlocking`
final class PhoneNumberBlocker: PhoneNumberBlocking {
    private let dbHelper: PersonalBlockingDBQuerying
    private let callDirectoryManager: CallDirectoryManaging

    init() throws {
        dbHelper = try PersonalBlockingDBHelper()
        callDirectoryManager = CallDirectoryManager.shared
    }

    init(dbHelper: PersonalBlockingDBQuerying, callDirectoryManager: CallDirectoryManaging) {
        self.dbHelper = dbHelper
        self.callDirectoryManager = callDirectoryManager
    }

    /// Block the given phone number
    ///
    /// - Parameters:
    ///   - e164OrShortCode: the phone number
    ///   - regionCode: the region code for the phone number
    ///   - onComplete: the completion handler
    func block(_ e164OrShortCode: CXCallDirectoryPhoneNumber,
               regionCode: String,
               onComplete: @escaping (Error?) -> Void) {
        let now = Date()
        let phoneNumberToBlock = BlockedPhoneNumberInfo(value: [
            "e164": e164OrShortCode,
            "regionCode": regionCode,
            "number": "\(e164OrShortCode)",
            "createTime": now.timeIntervalSince1970,
            "updateTime": now.timeIntervalSince1970
        ])
        do {
            try dbHelper.add(entries: [phoneNumberToBlock], updatePolicy: .error, checkLimit: true)

            callDirectoryManager.reload(extension: .blocking) { [weak self] result in
                switch result {
                case .success:
                    NotificationCenter.default.post(name: .blockedNumberListDidChangeNotification, object: nil)
                    onComplete(nil)
                case .failure(let error):
                    // restore
                    try? self?.dbHelper.removeFromDB(numbers: [phoneNumberToBlock.e164])
                    onComplete(error)
                }
            }
        } catch {
            onComplete(error)
        }
    }

    /// Unblock the given number
    ///
    /// - Parameters:
    ///   - e164OrShortCode: the given phone number
    ///   - onComplete: the completion handler
    func unblock(_ e164OrShortCode: CXCallDirectoryPhoneNumber, onComplete: @escaping (Error?) -> Void) {
        do {
            let numberToDelete: BlockedPhoneNumberInfo? = try dbHelper.getEntries().first { $0.e164 == e164OrShortCode }
            let currentKind = numberToDelete?.kind
            let currentUpdateTime = numberToDelete?.updateTime

            if let numberToDelete = numberToDelete {
                numberToDelete.kind = Kind.delete.rawValue
                numberToDelete.updateTime = Date().timeIntervalSince1970 + 1.0 // In case sync process spent less than 1 sec
                try dbHelper.update(entries: [numberToDelete])
            }

            callDirectoryManager.reload(extension: .blocking) { [weak self] result in
                switch result {
                case .success:
                    if let numberToDelete {
                        try? self?.dbHelper.removeFromDB(numbers: [numberToDelete.e164])
                    }
                    NotificationCenter.default.post(name: .blockedNumberListDidChangeNotification, object: nil)
                    onComplete(nil)
                case .failure(let error):
                    if let numberToDelete, let currentKind, let currentUpdateTime {
                        // restore object
                        numberToDelete.kind = currentKind
                        numberToDelete.updateTime = currentUpdateTime
                        try? self?.dbHelper.update(entries: [numberToDelete])
                    }

                    onComplete(error)
                }
            }
        } catch {
            onComplete(error)
        }
    }

    /// Query the given number to get whether it's blocked (i.e. exists in personal blocking DB)
    ///
    /// - Parameter e164OrShortCode: the given phone number
    /// - Returns: `true` if the number is added to personal blocking DB. `false` otherwise.
    func isBlocked(_ e164OrShortCode: CXCallDirectoryPhoneNumber) -> Bool {
        do {
            return try dbHelper.getExtensionEntries().contains { $0.e164 == e164OrShortCode }
        } catch {
            //logger.error("\(#function) failed: \(error)")
            return false
        }
    }

    // MARK: - async

    func block(_ e164OrShortCode: CXCallDirectoryPhoneNumber, regionCode: String) async throws {
        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
            block(e164OrShortCode, regionCode: regionCode) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        })
    }

    func unblock(_ e164OrShortCode: CXCallDirectoryPhoneNumber) async throws {
        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
            unblock(e164OrShortCode) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        })
    }
}

extension Notification.Name {
    static let blockedNumberListDidChangeNotification = Notification.Name("com.starhub.scambuster.blockedNumberListDidChangeNotification")
}
