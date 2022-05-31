//
//  SessionMonitor.swift
//  AppcuesKit
//
//  Created by James Ellis on 11/22/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation
import UIKit

internal protocol SessionMonitoring {
    func start()
    func reset()
}

internal enum SessionEvents: String, CaseIterable {
    case sessionStarted = "appcues:session_started"
    case sessionSuspended = "appcues:session_suspended"
    case sessionResumed = "appcues:session_resumed"
    case sessionReset = "appcues:session_reset"

    static var allNames: [String] { allCases.map { $0.rawValue } }
}

internal class SessionMonitor: SessionMonitoring {

    private weak var appcues: Appcues?
    private let storage: DataStoring
    private let publisher: AnalyticsPublishing
    private let tracker: AnalyticsTracking

    private let sessionTimeout: UInt

    private var applicationBackgrounded: Date?

    init(container: DIContainer) {
        self.appcues = container.owner
        self.publisher = container.resolve(AnalyticsPublishing.self)
        self.tracker = container.resolve(AnalyticsTracking.self)
        self.storage = container.resolve(DataStoring.self)
        self.sessionTimeout = container.resolve(Appcues.Config.self).sessionTimeout

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }

    // called on (A) sdk init (B) user identity change
    func start() {
        // if there is no user identified, we do not have a valid session
        guard !storage.userID.isEmpty else { return }

        appcues?.sessionID = UUID()
        publisher.track(SessionEvents.sessionStarted, properties: nil, interactive: true)
    }

    // called on reset(), user sign-out
    func reset() {
        // this is interactive: true since a reset should flush to network immediately (with previous user ID)
        // and the next session start will be sent in a new request, with the new user ID
        publisher.track(SessionEvents.sessionReset, properties: nil, interactive: true)
        appcues?.sessionID = nil
    }

    @objc
    func applicationWillEnterForeground(notification: Notification) {
        guard appcues?.sessionID != nil, let applicationBackgrounded = applicationBackgrounded else { return }

        let elapsed = Int(Date().timeIntervalSince(applicationBackgrounded))
        self.applicationBackgrounded = nil

        if elapsed >= sessionTimeout {
            publisher.track(SessionEvents.sessionStarted, properties: nil, interactive: true)
        } else {
            publisher.track(SessionEvents.sessionResumed, properties: nil, interactive: false)
        }
    }

    @objc
    func didEnterBackground(notification: Notification) {
        guard appcues?.sessionID != nil else { return }
        applicationBackgrounded = Date()
        publisher.track(SessionEvents.sessionSuspended, properties: nil, interactive: false)

        // ensure any pending in-memory analytics get processed asap
        tracker.flush()
    }
}
