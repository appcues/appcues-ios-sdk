//
//  SessionMonitor.swift
//  AppcuesKit
//
//  Created by James Ellis on 11/22/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation
import UIKit

internal protocol SessionMonitoring: AnyObject {
    var isSessionExpired: Bool { get }

    func start() -> Bool
    func updateLastActivity()
    func reset()
}

internal class SessionMonitor: SessionMonitoring {

    private weak var appcues: Appcues?
    private let storage: DataStoring
    private let tracker: AnalyticsTracking

    private let sessionTimeout: UInt

    private var lastActivityAt: Date?

    var isSessionExpired: Bool {
        guard let lastActivityAt = lastActivityAt else { return false }
        let elapsed = Int(Date().timeIntervalSince(lastActivityAt))
        return elapsed >= sessionTimeout
    }

    init(container: DIContainer) {
        self.appcues = container.owner
        self.tracker = container.resolve(AnalyticsTracking.self)
        self.storage = container.resolve(DataStoring.self)
        self.sessionTimeout = container.resolve(Appcues.Config.self).sessionTimeout

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    // called by AnalyticsPublisher on-demand, when it recognizes no session
    // exists, or the existing session has expired
    func start() -> Bool {
        // if there is no user identified, we do not have a valid session
        guard !storage.userID.isEmpty else { return false }
        appcues?.sessionID = UUID()
        updateLastActivity()
        return true
    }

    func updateLastActivity() {
        guard appcues?.sessionID != nil else { return }

        lastActivityAt = Date()
    }

    // called on reset(), user sign-out
    func reset() {
        // ensure any pending in-memory analytics get processed asap
        tracker.flush()

        appcues?.sessionID = nil
        lastActivityAt = nil
    }

    @objc
    func didEnterBackground(notification: Notification) {
        guard appcues?.sessionID != nil else { return }

        // ensure any pending in-memory analytics get processed asap
        tracker.flush()

        // clear out pending metrics
        SdkMetrics.clear()
    }
}
