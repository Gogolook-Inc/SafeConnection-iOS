//
//  SearchHistoryDBHelper.swift
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
class SearchHistoryDBHelper: SearchHistoryDBQuerying {
    static let maxAmount = 1000  // the maximum amount of records kept in search history

    // the parameters to determine
    private let compactDBFileSizeThreshold = 20 * 1024 * 1024   // 20 MB
    private let compactDBUsedPercentageThreshold = 0.5  // 50%

    private let fileCoordinator = NSFileCoordinator()
    private let dbURL: URL
    private let cipherKey: Data
    private let schemaVersion: UInt64

    /// The constructor designed for the project's use
    ///
    /// - Throws: the error encountered while getting DB's cipher key
    init() throws {
        dbURL = PersonalIdentificationDbManager.shared.getPersonalIdentificationDbURL()!
        cipherKey = try PersonalIdentificationDbManager.shared.getPersonalIdentificationDBCipherKey()
        schemaVersion = PersonalIdentificationDbManager.shared.getPersonalIdentificationDBSchemaVersion()
    }

    #if DEBUG || DR_WHO
    /// This constructor is designed for injecting dependencies for unit tests
    ///
    /// - Parameters:
    ///   - dbURL: the URL denoting the search history database
    ///   - cipherKey: the cipher key used to encrypt the database
    ///   - schemaVersion: the version of the schema of the search history database
    init(dbURL: URL, cipherKey: Data, schemaVersion: UInt64) {
        self.dbURL = dbURL
        self.cipherKey = cipherKey
        self.schemaVersion = schemaVersion
    }

    /// This method is to be used in unit test to verify result
    ///
    /// - Returns: all entries in search history db
    /// - Throws: database error
    func getEntries() throws -> [PhoneNumberInfo] {
        var result: [PhoneNumberInfo] = []
        var error: NSError?
        var dbError: Swift.Error?
        fileCoordinator.coordinate(writingItemAt: dbURL, options: [], error: &error) { url in
            autoreleasepool {
                do {
                    let realm = try Realm(configuration: getRealmConfig(fileURL: url))
                    result.append(contentsOf: realm.objects(PhoneNumberInfo.self).map { PhoneNumberInfo(value: $0) })
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
    #endif

    /// This method returns the entries needed by personal identification call directory extension
    ///
    /// - Returns: the entries containing non-nil label and sorted in ascending order by `e164`
    /// - Throws: database or file coordination error
    func getPersonalIdentificationEntries() throws -> [PhoneNumberInfo] {
        var result: [PhoneNumberInfo] = []
        var error: NSError?
        var dbError: Swift.Error?
        fileCoordinator.coordinate(writingItemAt: dbURL, options: [], error: &error) { url in
            autoreleasepool {
                do {
                    let realm = try Realm(configuration: getRealmConfig(fileURL: url))
                    result.append(contentsOf: realm.objects(PhoneNumberInfo.self).filter("label != nil").sorted(byKeyPath: "e164").map { PhoneNumberInfo(value: $0) })
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

    /// The method returns the entries needed by search history
    ///
    /// - Returns: the entries sorted in descending order by `timestamp`
    /// - Throws: database or file coordination error
    func getSearchHistoryEntries() throws -> [PhoneNumberInfo] {
        var result: [PhoneNumberInfo] = []
        var error: NSError?
        var dbError: Swift.Error?
        fileCoordinator.coordinate(writingItemAt: dbURL, options: [], error: &error) { url in
            autoreleasepool {
                do {
                    let realm = try Realm(configuration: getRealmConfig(fileURL: url))
                    result.append(contentsOf: realm.objects(PhoneNumberInfo.self).filter("isInSearchHistory = true")
                        .sorted(byKeyPath: "timestamp", ascending: false)
                        .map { PhoneNumberInfo(value: $0) })
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

    /// Add entries to the database
    ///
    /// - Parameters:
    ///   - entries: Unmanaged objects to be added, where none of their `e164` shall exist in the database
    ///   - updatePolicy: `.error`, `.modified` or `.all`
    /// - Throws: database or file coordination error
    func add(entries: [PhoneNumberInfo], updatePolicy: UpdatePolicy = .error) throws {
        guard Set<CXCallDirectoryPhoneNumber>(entries.map { $0.e164 }).count == entries.count else {
            throw Error(with: .inputDuplicateE164)
        }

        var error: NSError?
        var dbError: Swift.Error?
        fileCoordinator.coordinate(writingItemAt: dbURL, options: [], error: &error) { url in
            autoreleasepool {
                do {
                    let realm = try Realm(configuration: getRealmConfig(fileURL: url))

                    let predicate = NSPredicate(format: "e164 IN %@", entries.map { $0.e164 })
                    let existingEntries = realm.objects(PhoneNumberInfo.self).filter(predicate)
                    guard existingEntries.isEmpty || updatePolicy != .error else {
                        throw Error(with: .entryAlreadyExists)
                    }
                    try realm.write {
                        realm.add(entries.map { PhoneNumberInfo(value: $0) }, update: updatePolicy)
                    }

                    // remove the records beyond the limit
                    let entries = Array(realm.objects(PhoneNumberInfo.self).sorted(byKeyPath: "timestamp", ascending: false))
                    if entries.count > Self.maxAmount {
                        let entriesToRemove = entries[(Self.maxAmount)...]
                        try realm.write {
                            realm.delete(entriesToRemove)
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

    /// Hide the entries, from search history, whose `e164` is in `numbers`
    ///
    /// - Parameter numbers: a list of phone numbers to be hidden from search history
    /// - Throws: database or file coordination error
    func markAsRemovedFromSearchHistory(numbers: [CXCallDirectoryPhoneNumber]) throws {
        var error: NSError?
        var dbError: Swift.Error?
        fileCoordinator.coordinate(writingItemAt: dbURL, options: [], error: &error) { url in
            autoreleasepool {
                do {
                    let realm = try Realm(configuration: getRealmConfig(fileURL: url))
                    let predicate = NSPredicate(format: "e164 IN %@", numbers)
                    let targets = realm.objects(PhoneNumberInfo.self).filter(predicate)
                    try realm.write {
                        for target in targets {
                            target.isInSearchHistory = false
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

    /// Remove the entries, from the database, whose `e164` is in `numbers`
    ///
    /// - Parameter numbers: a list of the phone numbers to be deleted from the database
    /// - Throws: database or file coordination error
    func removeFromDB(numbers: [CXCallDirectoryPhoneNumber]) throws {
        var error: NSError?
        var dbError: Swift.Error?
        fileCoordinator.coordinate(writingItemAt: dbURL, options: [], error: &error) { url in
            autoreleasepool {
                do {
                    let realm = try Realm(configuration: getRealmConfig(fileURL: url))
                    let predicate = NSPredicate(format: "e164 IN %@", numbers)
                    let targets = realm.objects(PhoneNumberInfo.self).filter(predicate)
                    try realm.write {
                        realm.delete(targets)
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

    /// Update the entries by their properties (except `e164` where it's used to locate a specific entry)
    ///
    /// - Parameter entries: the entries to be updated
    /// - Throws: database or file coordination error
    func update(entries: [PhoneNumberInfo]) throws {
        guard Set<CXCallDirectoryPhoneNumber>(entries.map { $0.e164 }).count == entries.count else {
            throw Error(with: .inputDuplicateE164)
        }

        var error: NSError?
        var dbError: Swift.Error?
        fileCoordinator.coordinate(writingItemAt: dbURL, options: [], error: &error) { url in
            autoreleasepool {
                do {
                    let realm = try Realm(configuration: getRealmConfig(fileURL: url))
                    let predicate = NSPredicate(format: "e164 IN %@ AND isInSearchHistory = true", entries.map { $0.e164 })
                    let targetEntries = realm.objects(PhoneNumberInfo.self).filter(predicate).sorted(byKeyPath: "e164")

                    guard targetEntries.count == entries.count else {
                        throw Error(with: .entryNotFound)
                    }
                    let sortedUnmanagedEntries = entries.sorted { $0.e164 < $1.e164 }
                    for (targetEntry, unmanagedEntry) in zip(targetEntries, sortedUnmanagedEntries) {
                        assert(unmanagedEntry.e164 == targetEntry.e164)
                        try realm.write {
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

    /// Indicates if an `e164` exists in the database
    ///
    /// - Parameter e164: the interested `e164`
    /// - Returns: `true` if the `e164` exists in the DB. `false` otherwise
    /// - Throws: database for file coordination error
    func hasTheEntry(e164: CXCallDirectoryPhoneNumber) throws -> Bool {
        var result = false
        var error: NSError?
        var dbError: Swift.Error?
        fileCoordinator.coordinate(writingItemAt: dbURL, options: [], error: &error) { url in
            autoreleasepool {
                do {
                    let realm = try Realm(configuration: getRealmConfig(fileURL: url))
                    result = realm.object(ofType: PhoneNumberInfo.self, forPrimaryKey: e164) != nil
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
        return result
    }

    func getEntryCount() throws -> Int {
        var count: Int = 0
        var error: NSError?
        var dbError: Swift.Error?
        fileCoordinator.coordinate(writingItemAt: dbURL, options: [], error: &error) { url in
            autoreleasepool {
                do {
                    let realm = try Realm(configuration: getRealmConfig(fileURL: url))
                    count = realm.objects(PhoneNumberInfo.self).filter("isInSearchHistory = true").count
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

                    // get different records and restore
                    let existingEntries: [CXCallDirectoryPhoneNumber] = realm.objects(PhoneNumberInfo.self)
                        .filter("isInSearchHistory = true")
                        .value(forKey: "e164") as! [CXCallDirectoryPhoneNumber]
                    let entriesToRestore: [PhoneNumberInfo] = realmToRestore.objects(PhoneNumberInfo.self)
                        .filter("isInSearchHistory = true")
                        .filter(NSPredicate(format: "NOT e164 IN %@", existingEntries))
                        .map { PhoneNumberInfo(value: $0) }
                    if !entriesToRestore.isEmpty {
                        try realm.write {
                            realm.add(entriesToRestore, update: .modified)
                        }
                    }

                    // remove the records beyond the limit
                    let entries = Array(realm.objects(PhoneNumberInfo.self).sorted(byKeyPath: "timestamp", ascending: false))
                    if entries.count > Self.maxAmount {
                        let entriesToRemove = entries[(Self.maxAmount)...]
                        try realm.write {
                            realm.delete(entriesToRemove)
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
                                   objectTypes: [PhoneNumberInfo.self])
    }
}
// swiftlint:enable file_length type_body_length
