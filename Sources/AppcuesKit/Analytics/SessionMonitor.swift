//
//  SessionMonitor.swift
//  AppcuesKit
//
//  Created by James Ellis on 11/22/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation
import UIKit

internal class SessionMonitor {

    enum SessionEvents: String {
        case sessionStarted = "appcues:session_started"
        case sessionSuspended = "appcues:session_suspended"
        case sessionResumed = "appcues:session_resumed"
        case sessionReset = "appcues:session_reset"
    }

    private let storage: Storage
    private let publisher: AnalyticsPublisher

    private let sessionTimeout: UInt

    private var applicationBackgrounded: Date?
    private (set) var sessionID: UUID?

    var isActive: Bool {
        sessionID != nil
    }

    init(container: DIContainer) {
        self.publisher = container.resolve(AnalyticsPublisher.self)
        self.storage = container.resolve(Storage.self)
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

        sessionID = UUID()
        publisher.track(SessionEvents.sessionStarted, properties: nil, sync: true)
    }

    // called on reset(), user sign-out
    func reset() {
        publisher.track(SessionEvents.sessionReset, properties: nil, sync: false)
        sessionID = nil
    }

    @objc
    func applicationWillEnterForeground(notification: Notification) {
        guard sessionID != nil, let applicationBackgrounded = applicationBackgrounded else { return }

        let elapsed = Int(Date().timeIntervalSince(applicationBackgrounded))
        self.applicationBackgrounded = nil

        if elapsed >= sessionTimeout {
            publisher.track(SessionEvents.sessionStarted, properties: nil, sync: true)
        } else {
            publisher.track(SessionEvents.sessionResumed, properties: nil, sync: false)
        }
    }

    @objc
    func didEnterBackground(notification: Notification) {
        guard sessionID != nil else { return }
        applicationBackgrounded = Date()
        publisher.track(SessionEvents.sessionSuspended, properties: nil, sync: false)
    }
}
