//
//  PersonalBlockingDBHelper.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/6/27.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import CallKit
internal import RealmSwift

// swiftlint:disable file_length type_body_length

/// This class provides DB operations at the level of project's business logic
/// By the nature of Realm DB, the entries returned by helpers' methods are `managed` objects.
///
/// To circumvent the problem of not supporting encrypted realm DBs across process, this DB helper
/// has to return to the invokers `unmanaged` realm objects to close the accessing Realm DB as soon as possible.
/// As a consequence, the invokers has to manage the updates of its retaining `unmanaged` objects.
///
/// The entries passed as the parameter for `add` and  method should be `unmanaged` objects.
/// The realm objects passed as the parameters for `update` and `remove` methods should be `unmanaged` objects,
/// as changing managed objects should always happen in realm's `write` closure.
///
/// Note that: the entries returned should adhere Realm DB's rule, and they not be used accross threads.
class PersonalBlockingDBHelper: PersonalBlockingDBQuerying {
    static let maxBlockingAmount = 500

    // the parameters to determine
    private let compactDBFileSizeThreshold = 10 * 1024 * 1024   // 10 MB
    private let compactDBUsedPercentageThreshold = 0.5  // 50%

    private let fileCoordinator = NSFileCoordinator()
    private let dbURL: URL
    private let cipherKey: Data
    private let schemaVersion: UInt64

    /// The constructor designed for the project's use
    ///
    /// - Throws: the error encountered while getting DB's cipher key
    init() throws {
        //let appProperties = AppProperties.make()
        dbURL = PersonalBlockDbManager.shared.getPersonalBlockDbURL()!
        cipherKey = try PersonalBlockDbManager.shared.getPersonalBlockingDBCipherKey()
        schemaVersion = PersonalBlockDbManager.shared.getPersonalBlockingDBSchemaVersion()
        print("dbURL: \(dbURL) cipherKey: \(cipherKey) schemaVersion: \(schemaVersion)")
    }

    /// This constructor is designed for injecting dependencies for unit tests
    ///
    /// - Parameters:
    ///   - dbURL: the URL denoting the personal blocking database
    ///   - cipherKey: the cipher key used to encrypt the database
    ///   - schemaVersion: the version of the schema of the personal blocking database
    init(dbURL: URL, cipherKey: Data, schemaVersion: UInt64) {
        self.dbURL = dbURL
        self.cipherKey = cipherKey
        self.schemaVersion = schemaVersion
    }

    /// Get the all entries for personal blocking call directory extension
    ///
    /// - Returns: the entries (`BlockType` = `.phone`) to be loaded by personal blocking call directory extension, sorted by `e164` in ascending order
    /// - Throws: database or file coordination error
    func getEntries() throws -> [BlockedPhoneNumberInfo] {
        var result: [BlockedPhoneNumberInfo] = []
        var error: NSError?
        var dbError: Swift.Error?
        fileCoordinator.coordinate(writingItemAt: dbURL, options: [], error: &error) { url in
            autoreleasepool {
                do {
                    let realm = try Realm(configuration: getRealmConfig(fileURL: url))
                    result.append(contentsOf: realm.objects(BlockedPhoneNumberInfo.self).map { BlockedPhoneNumberInfo(value: $0) })
                } catch {
                    dbError = error
                    return
                }
            }
        }
        if error != nil {
            throw error!
        }
        if dbError != nil {
            throw dbError!
        }
        return result
    }

    /// Get the entries for personal blocking call directory extension (filtered with block type = phone, not deleted, and sorted by e164 in ascending order)
    ///
    /// - Returns: the entries (`BlockType` = `.phone`) to be loaded by personal blocking call directory extension, sorted by `e164` in ascending order
    /// - Throws: database or file coordination error
    func getExtensionEntries() throws -> [BlockedPhoneNumberInfo] {
        var result: [BlockedPhoneNumberInfo] = []
        var error: NSError?
        var dbError: Swift.Error?
        fileCoordinator.coordinate(writingItemAt: dbURL, options: [], error: &error) { url in
            autoreleasepool {
                do {
                    let realm = try Realm(configuration: getRealmConfig(fileURL: url))
                    let predicate = NSPredicate(format: "type = %d AND kind != %d", BlockType.phone.rawValue, Kind.delete.rawValue)
                    result.append(contentsOf: realm.objects(BlockedPhoneNumberInfo.self).filter(predicate).sorted(byKeyPath: "e164").map { BlockedPhoneNumberInfo(value: $0) })
                } catch {
                    dbError = error
                    return
                }
            }
        }
        if error != nil {
            throw error!
        }
        if dbError != nil {
            throw dbError!
        }
        return result
    }

    /// This method returns the all blocked phone numbers, filtered with block type = phone
    /// and sorted by `createTime` in descending order.
    /// This sorting predicate is defined particularly or UI presentation.
    ///
    /// - Returns: All blocked phone numbers
    /// - Throws: database or file coordination errors
    func getUIEntries() throws -> [BlockedPhoneNumberInfo] {
        var result: [BlockedPhoneNumberInfo] = []
        var error: NSError?
        var dbError: Swift.Error?
        fileCoordinator.coordinate(writingItemAt: dbURL, options: [], error: &error) { url in
            autoreleasepool {
                do {
                    let realm = try Realm(configuration: getRealmConfig(fileURL: url))
                    let predicate = NSPredicate(format: "type = %d AND kind != %d", BlockType.phone.rawValue, Kind.delete.rawValue)
                    let numbers = realm.objects(BlockedPhoneNumberInfo.self)
                        .filter(predicate)
                        .sorted(byKeyPath: "createTime", ascending: false)
                        .map { BlockedPhoneNumberInfo(value: $0) }
                    result.append(contentsOf: numbers)
                } catch {
                    dbError = error
                    return
                }
            }
        }
        if error != nil {
            throw error!
        }
        if dbError != nil {
            throw dbError!
        }
        
        return result
    }

    /// Add unmanaged entries to the database
    ///
    /// - Parameters:
    ///   - entries: Unmanaged objects of `BlockedPhoneNumberInfo` to be added to the database
    ///   - updatePolicy: `.error`, `.modified` or `.all`
    ///   - checkLimit: whether to check the maximum amount allowed to add into the blocking list.
    ///   `false` allows to add entries beyond the limit and it should be used ONLY for
    ///   syncing a user's block list from the server.
    /// - Throws: database or file coordination error
    func add(entries: [BlockedPhoneNumberInfo], updatePolicy: UpdatePolicy = .error, checkLimit: Bool = true) throws {
        guard Set<CXCallDirectoryPhoneNumber>(entries.map { $0.e164 }).count == entries.count || updatePolicy != .error else {
            throw Error(with: .inputDuplicateE164)
        }

        var error: NSError?
        var dbError: Swift.Error?
        fileCoordinator.coordinate(writingItemAt: dbURL, options: [], error: &error) { url in
            autoreleasepool {
                do {
                    let realm = try Realm(configuration: getRealmConfig(fileURL: url))

                    let predicate = NSPredicate(format: "e164 IN %@", entries.map { $0.e164 })
                    let existingEntries = realm.objects(BlockedPhoneNumberInfo.self).filter(predicate)
                    guard existingEntries.isEmpty || updatePolicy != .error else {
                        throw Error(with: .entryAlreadyExists)
                    }

                    // NOTE: The quota for blocking counts all blocked entries, regardless their `BlockType`.
                    guard !checkLimit || calculateRemainingBlockingQuota(consumedAmount: realm.objects(BlockedPhoneNumberInfo.self).count,
                                                                         updatePolicy: updatePolicy,
                                                                         existingEntryAmount: existingEntries.count,
                                                                         inputEntryAmount: entries.count) >= 0 else {
                                                                            throw Error(with: .reachedLimit)
                    }

                    try realm.write {
                        print("entries to be added: \(entries)")
                        realm.add(entries.map { BlockedPhoneNumberInfo(value: $0) }, update: updatePolicy)
                    }
                } catch let error as NSError  {
                    dbError = error
                    print("Realm Error: \(error.localizedDescription)")
                    if let userInfo = error.userInfo as? [String: Any] {
                        print("User Info: \(userInfo)")
                    }
                    return
                }
            }
        }
        if error != nil {
            throw error!
        }
        if dbError != nil {
            throw dbError!
        }
    }

    /// Remove entries in the database by phone numbers
    ///
    /// - Parameter numbers: the phone numbers to be used as the primary key to allocate the targets of number removal
    /// - Throws: database or file coordination errors
    func removeFromDB(numbers: [CXCallDirectoryPhoneNumber]) throws {
        var error: NSError?
        var dbError: Swift.Error?
        fileCoordinator.coordinate(writingItemAt: dbURL, options: [], error: &error) { url in
            autoreleasepool {
                do {
                    let realm = try Realm(configuration: getRealmConfig(fileURL: url))
                    let predicate = NSPredicate(format: "e164 IN %@", numbers)
                    let targetObjects = realm.objects(BlockedPhoneNumberInfo.self).filter(predicate)
                    try realm.write {
                        realm.delete(targetObjects)
                    }
                } catch {
                    dbError = error
                    return
                }
            }
        }
        if error != nil {
            throw error!
        }
        if dbError != nil {
            throw dbError!
        }
    }

    /// Remove all blocked number info from the DB.
    /// - Throws: database or file coordination error
    func removeAllBlockedPhoneNumberInfo() throws {
        var error: NSError?
        var dbError: Swift.Error?
        fileCoordinator.coordinate(writingItemAt: dbURL, options: [], error: &error) { url in
            autoreleasepool {
                do {
                    let realm = try Realm(configuration: getRealmConfig(fileURL: url))
                    let blockedNumberInfoEntries = realm.objects(BlockedPhoneNumberInfo.self)

                    // Delete all blocked lists
                    try realm.write {
                        realm.delete(blockedNumberInfoEntries)
                    }
                } catch {
                    dbError = error
                    return
                }
            }
        }
        if error != nil {
            throw error!
        }
        if dbError != nil {
            throw dbError!
        }
    }

    /// This method returns the remaining quota available for blocking.
    ///
    /// - Returns: the remainging quota available. Note that the value may be negative numbers, as some users may have blocked entries over the limit.
    /// - Throws: realm db or file coordination errors
    func getRemainingQuota() throws -> Int {
        var result: Int = 0
        var error: NSError?
        var dbError: Swift.Error?
        fileCoordinator.coordinate(writingItemAt: dbURL, options: [], error: &error) { url in
            autoreleasepool {
                do {
                    let realm = try Realm(configuration: getRealmConfig(fileURL: url))
                    result = Self.maxBlockingAmount - realm.objects(BlockedPhoneNumberInfo.self).count
                } catch {
                    dbError = error
                    return
                }
            }
        }
        if error != nil {
            throw error!
        }
        if dbError != nil {
            throw dbError!
        }
        return result
    }

    func getSyncTime() throws -> TimeInterval? {
        var result: TimeInterval?
        var error: NSError?
        var dbError: Swift.Error?
        fileCoordinator.coordinate(writingItemAt: dbURL, options: [], error: &error) { url in
            autoreleasepool {
                do {
                    let realm = try Realm(configuration: getRealmConfig(fileURL: url))
                    if let syncTime = realm.object(ofType: LastSyncTime.self, forPrimaryKey: LastSyncTime.uniqueId) {
                        result = LastSyncTime(value: syncTime).syncTime
                    }
                } catch {
                    dbError = error
                    return
                }
            }
        }
        if error != nil {
            throw error!
        }
        if dbError != nil {
            throw dbError!
        }
        return result
    }

    func update(syncTime: TimeInterval?) throws {
        var error: NSError?
        var dbError: Swift.Error?
        fileCoordinator.coordinate(writingItemAt: dbURL, options: [], error: &error) { url in
            autoreleasepool {
                do {
                    let realm = try Realm(configuration: getRealmConfig(fileURL: url))
                    try realm.write {
                        if let syncTime = syncTime { // update/add last sync time
                            if let lastSyncTime = realm.object(ofType: LastSyncTime.self, forPrimaryKey: LastSyncTime.uniqueId) {
                                lastSyncTime.syncTime = syncTime
                            } else {
                                realm.add(LastSyncTime(value: ["id": LastSyncTime.uniqueId, "syncTime": syncTime] as [String: Any]))
                            }
                        } else {    // remove last sync time
                            realm.delete(realm.objects(LastSyncTime.self))
                        }
                    }
                } catch {
                    dbError = error
                    return
                }
            }
        }
        if error != nil {
            throw error!
        }
        if dbError != nil {
            throw dbError!
        }
    }

    func getEntryCount() throws -> Int {
        var count: Int = 0
        var error: NSError?
        var dbError: Swift.Error?
        fileCoordinator.coordinate(writingItemAt: dbURL, options: [], error: &error) { url in
            autoreleasepool {
                do {
                    let realm = try Realm(configuration: getRealmConfig(fileURL: url))
                    let predicate = NSPredicate(format: "type = %d AND kind != %d", BlockType.phone.rawValue, Kind.delete.rawValue)
                    count = realm.objects(BlockedPhoneNumberInfo.self).filter(predicate).count
                } catch {
                    dbError = error
                    return
                }
            }
        }
        if error != nil {
            throw error!
        }
        if dbError != nil {
            throw dbError!
        }
        return count
    }

    /// This method update all provided entries
    /// - Parameter entries: Entries need be changed
    func update(entries: [BlockedPhoneNumberInfo]) throws {
        var error: NSError?
        var dbError: Swift.Error?
        fileCoordinator.coordinate(writingItemAt: dbURL, options: [], error: &error) { url in
            autoreleasepool {
                do {
                    let realm = try Realm(configuration: getRealmConfig(fileURL: url))
                    let predicate = NSPredicate(format: "e164 IN %@", entries.map { $0.e164 })
                    let targetEntries = realm.objects(BlockedPhoneNumberInfo.self).filter(predicate)
                    guard targetEntries.count == entries.count else {
                        throw Error(with: .entryNotFound)
                    }
                    try realm.write {
                        targetEntries.forEach { targetEntry in
                            guard let unmanagedEntry = entries.first(where: { $0.e164 == targetEntry.e164 }) else {
                                return
                            }
                            realm.update(targetEntry, with: unmanagedEntry)
                        }
                    }
                } catch {
                    dbError = error
                    return
                }
            }
        }
        if error != nil {
            throw error!
        }
        if dbError != nil {
            throw dbError!
        }
    }

    /// Merge data from another DB into current DB.
    ///
    /// > Warning: If necessary, callers need to handle the lock of the source DB file passed via `url` parameter between threads or processes by themselves.
    ///
    /// - Parameters:
    ///     - url: The URL of source DB.
    ///     - cipherKey: The cipher used to decrypt source DB.
    ///     - schemaVersion: The schema version of source DB.
    ///
    /// - Throws: `NSError` if failed to lock file.
    /// - Throws: `RLMError.Code` if something is wrong from Realm.
    func restore(from url: URL, with cipherKey: Data, schemaVersion: UInt64) throws {
        var error: NSError?
        var dbError: Swift.Error?

        fileCoordinator.coordinate(writingItemAt: dbURL, options: [], error: &error) { dbURL in
            autoreleasepool {
                do {
                    let realm = try Realm(configuration: getRealmConfig(fileURL: dbURL))
                    let configOfBackup = getRealmConfig(fileURL: url, cipherKey: cipherKey, schemaVersion: schemaVersion)
                    let realmToRestore = try Realm(configuration: configOfBackup)

                    let existingEntries: [CXCallDirectoryPhoneNumber] = realm.objects(BlockedPhoneNumberInfo.self)
                        .filter("kind != %d", Kind.delete.rawValue)
                        .value(forKey: "e164") as! [CXCallDirectoryPhoneNumber]
                    let entriesToRestore: [BlockedPhoneNumberInfo] = realmToRestore.objects(BlockedPhoneNumberInfo.self)
                        .filter("kind != %d", Kind.delete.rawValue)
                        .filter(NSPredicate(format: "NOT e164 IN %@", existingEntries))
                        .map { BlockedPhoneNumberInfo(value: $0) }
                    if !entriesToRestore.isEmpty {
                        try realm.write {
                            realm.add(entriesToRestore, update: .modified)
                        }
                    }
                } catch {
                    dbError = error
                }
            }
        }

        if error != nil {
            throw error!
        }
        if dbError != nil {
            throw dbError!
        }
    }

    // MARK: Private

    private func getRealmConfig(fileURL: URL) -> Realm.Configuration {
        getRealmConfig(fileURL: fileURL, cipherKey: cipherKey, schemaVersion: schemaVersion)
    }

    private func getRealmConfig(fileURL: URL, cipherKey: Data, schemaVersion: UInt64) -> Realm.Configuration {
        return Realm.Configuration(fileURL: fileURL,
                                   encryptionKey: cipherKey,
                                   readOnly: false,
                                   schemaVersion: schemaVersion,
                                   shouldCompactOnLaunch: { totalBytes, usedBytes -> Bool in
                                    return (totalBytes > self.compactDBFileSizeThreshold)
                                        && (Double(usedBytes) / Double(totalBytes)) < self.compactDBUsedPercentageThreshold
        },
                                   objectTypes: [LastSyncTime.self, BlockedPhoneNumberInfo.self])
    }

    private func calculateRemainingBlockingQuota(maxBlockingAmount: Int = PersonalBlockingDBHelper.maxBlockingAmount,
                                                 consumedAmount: Int,
                                                 updatePolicy: UpdatePolicy,
                                                 existingEntryAmount: Int,
                                                 inputEntryAmount: Int) -> Int {
        var remainingQuota = maxBlockingAmount
        switch updatePolicy {
        case .error:
            remainingQuota -= (consumedAmount + inputEntryAmount)
        case .all, .modified:
            remainingQuota -= (consumedAmount - existingEntryAmount + inputEntryAmount)
        }
        return remainingQuota
    }
}
// swiftlint:enable file_length type_body_length
