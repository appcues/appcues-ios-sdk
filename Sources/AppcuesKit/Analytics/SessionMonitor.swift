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
        case sessionEnded = "appcues:session_ended"
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
        publisher.track(name: SessionEvents.sessionStarted.rawValue)
    }

    // called on reset(), user sign-out
    func end() {
        publisher.track(name: SessionEvents.sessionEnded.rawValue)
        sessionID = nil
    }

    @objc
    func applicationWillEnterForeground(notification: Notification) {
        guard sessionID != nil, let applicationBackgrounded = applicationBackgrounded else { return }

        let elapsed = Int(Date().timeIntervalSince(applicationBackgrounded))
        self.applicationBackgrounded = nil

        if elapsed >= sessionTimeout {
            publisher.track(name: SessionEvents.sessionStarted.rawValue)
        } else {
            publisher.track(name: SessionEvents.sessionResumed.rawValue)
        }
    }

    @objc
    func didEnterBackground(notification: Notification) {
        guard sessionID != nil else { return }
        applicationBackgrounded = Date()
        publisher.track(name: SessionEvents.sessionSuspended.rawValue)
    }
}
