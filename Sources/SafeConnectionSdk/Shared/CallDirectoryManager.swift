//
//  CallDirectoryManager.swift
//  Merli
//
//  Created by Henry Tseng on 2019/5/6.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import CallKit
import Combine
import UIKit

protocol CallDirectoryManaging {
    func getEnabledStatusForExtensions(_ extensions: [CallDirExt]) -> Bool
    func waitForStatusUpdated(_ updatedHandler: @escaping () -> Void)
    func updateExtensionsStatus(_ extensions: [CallDirExt]) async throws
    func reload(extension ext: CallDirExt, complete: @escaping (Result<Void, Error>) -> Void)
    func reload(extensions: [CallDirExt]) async throws
    func openSettings(completionHandler completion: ((Result<Void, Error>) -> Void)?)
    func updateAndGetEnabledStatusForExtension(_ ext: CallDirExt, complete: @escaping (Bool) -> Void)
}

protocol CXCallDirectoryManaging {
    func reloadExtension(withIdentifier identifier: String, completionHandler completion: ((Error?) -> Void)?)
    func getEnabledStatusForExtension(withIdentifier identifier: String, completionHandler completion: @escaping (CXCallDirectoryManager.EnabledStatus, Error?) -> Void)
    func openSettings(completionHandler completion: ((Error?) -> Void)?)
}
extension CXCallDirectoryManager: CXCallDirectoryManaging {}

class CallDirectoryManager: CallDirectoryManaging {

    static let statusDidUpdateNotification: Notification.Name = Notification.Name("callDirectoryExtensionsStatusDidUpdate")
#if targetEnvironment(simulator)
    static let shared: CallDirectoryManager = CallDirectoryManager(cxCallDirectoryManager: FakeCallDirectoryManager())
#else
    static let shared = CallDirectoryManager()
#endif

    private var properties: OfflineDBCallDirectoryProperties = SharedLocalStorage.shared
//    private var debugConfigurations: ProductionDebugConfiguring = SharedLocalStorage.shared
    var manager: CXCallDirectoryManaging = CXCallDirectoryManager.sharedInstance
    private var statuses: [CallDirExt: Bool] = [:]
    private var isStatusUpdating: Bool = false
    @Published private var isStatusUpdated: Bool = false

    private var cancellables: Set<AnyCancellable> = []

    enum UpdateError: LocalizedError {
        case timeout

        var errorDescription: String? {
            return "Call directory timeout."
        }
    }

    init(cxCallDirectoryManager: CXCallDirectoryManaging? = nil) {
        if let cxCallDirectoryManager = cxCallDirectoryManager {
            self.manager = cxCallDirectoryManager
        }

        NotificationCenter.default.publisher(for: Notification.Name("gogolook.scambuster.BackupViewControllerDidRestoreNotification"), object: nil)
            .sink { [weak self] _ in
                Task { [weak self] in
                    try? await self?.reload(extensions: [.identification, .blocking])
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .dropFirst()
            .sink { _ in
                Task { [weak self] in
                    try? await self?.updateExtensionsStatus(CallDirExt.allCases)
                }
            }
            .store(in: &cancellables)
    }

    /// Get enabled status of extensions in memory
    /// - Parameter extensions: The call directory extensions
    /// - Returns: The enabled status of extensions, only return `true` if *ALL* extensions are enabled
    func getEnabledStatusForExtensions(_ extensions: [CallDirExt]) -> Bool {
        var isAllEnabled = true
        for ext in extensions {
            let isEnabled = isExtensionEnabled(ext)
            isAllEnabled = isAllEnabled && isEnabled
        }
        return isAllEnabled
    }

    /// Waiting if call directory status has not been updated
    /// - Parameter updatedHandler: the handler will be called after updated
    func waitForStatusUpdated(_ updatedHandler: @escaping () -> Void) {
        guard isStatusUpdated else {
            $isStatusUpdated
                .first(where: { $0 })
                .sink { _ in
                    updatedHandler()
                }
                .store(in: &cancellables)
            return
        }
        updatedHandler()
    }

    /// Reload call directory extension
    /// - Parameters:
    ///   - ext: The call directory extension
    ///   - complete: Completion callback
    func reload(extension ext: CallDirExt, complete: @escaping (Result<Void, Error>) -> Void) {
//        if let error = debugConfigurations.forceOfflineDBReloadFailedError {
//            complete(.failure(error))
//            return
//        }
        manager.reloadExtension(withIdentifier: ext.identifier, completionHandler: { error in
            if let error {
                self.handleReloadFailure(ext: ext, error: error)
                complete(.failure(error))
            } else {
                complete(.success(()))
            }
        })
    }

    /// Reload call directory extensions in Concurrency way
    /// - Parameter extensions: The call directory extensions
    func reload(extensions: [CallDirExt]) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for ext in extensions {
                group.addTask {
                    try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
                        self.reload(extension: ext, complete: continuation.resume(with:))
                    })
                }
            }
            try await group.waitForAll()
        }
    }

    /// Open Call Blocking & Identification in Settings
    ///
    /// - Parameter completion: completion callback closure with result
    func openSettings(completionHandler completion: ((Result<Void, Error>) -> Void)?) {
        manager.openSettings { error in
            if let error = error {
                //logger.error("Can't open Settings", error: error)
                completion?(.failure(error))
            } else {
                completion?(.success(()))
            }
        }
    }

    /// Update statuses of extensions and keep in memory
    /// - Parameter extensions: The call directory extensions
    func updateExtensionsStatus(_ extensions: [CallDirExt]) async throws {
        guard !isStatusUpdating else {
            return
        }
        isStatusUpdated = false
        isStatusUpdating = true
        statuses = try await withThrowingTaskGroup(of: [CallDirExt: Bool].self) { group in
            for ext in extensions {
                group.addTask {
                    try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<[CallDirExt: Bool], Error>) in
                        self.manager.getEnabledStatusForExtension(withIdentifier: ext.identifier) { status, error in
                            if let error {
                                continuation.resume(throwing: error)
                            } else {
                                let isEnabled = status == .enabled
                                continuation.resume(returning: [ext: isEnabled])
                            }
                        }
                    })
                }
            }
            let statuses = try await group.reduce(into: [:]) { result, status in
                result.merge(status) { current, _ in current }
            }
            return statuses
        }
        isStatusUpdating = false
        isStatusUpdated = true
        NotificationCenter.default.post(name: Self.statusDidUpdateNotification, object: nil)
    }

    func updateAndGetEnabledStatusForExtension(_ ext: CallDirExt, complete: @escaping (Bool) -> Void) {
        self.manager.getEnabledStatusForExtension(withIdentifier: ext.identifier) { [weak self] (status, error) in
            if error != nil {
                complete(false)
            } else {
                let isEnabled = status == .enabled
                self?.statuses[ext] = isEnabled
                complete(isEnabled)
            }
        }
    }

    private func isExtensionEnabled(_ ext: CallDirExt) -> Bool {
        statuses[ext] ?? false
    }

    private func handleReloadFailure(ext: CallDirExt, error: Error) {
        guard ext == .offlineDB else {
            return
        }
        if let error = error as? CXErrorCodeCallDirectoryManagerError,
            error.code == CXErrorCodeCallDirectoryManagerError.currentlyLoading {
            // Do nothing
        } else {
            // CmdResult should always exist after reload
            self.properties.offlineDBExtCmdResult = CXCmdResult(
                commandTypeId: self.properties.offlineDBExtCmdResult?.commandTypeId ?? .doNothing,
                isSucceeded: false,
                errorMessage: error.localizedDescription
            )
        }
    }
}
