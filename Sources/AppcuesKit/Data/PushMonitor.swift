//
//  PushMonitor.swift
//  AppcuesKit
//
//  Created by Matt on 2024-02-22.
//  Copyright © 2024 Appcues. All rights reserved.
//

import UIKit

internal protocol PushMonitoring: AnyObject {
    var pushEnabled: Bool { get }
    var pushBackgroundEnabled: Bool { get }
}

internal class PushMonitor: PushMonitoring {

    private let storage: DataStoring

    private var pushAuthorizationStatus: UNAuthorizationStatus = .notDetermined

    var pushEnabled: Bool {
        pushAuthorizationStatus == .authorized && storage.pushToken != nil
    }

    var pushBackgroundEnabled: Bool {
        storage.pushToken != nil
    }

    init(container: DIContainer) {
        self.storage = container.resolve(DataStoring.self)

        refreshPushStatus()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc
    private func applicationWillEnterForeground(notification: Notification) {
        refreshPushStatus()
    }

    private func refreshPushStatus() {
        // Skip call to UNUserNotificationCenter.current() in tests to avoid crashing in package tests
        #if DEBUG
        guard ProcessInfo.processInfo.environment["XCTestBundlePath"] == nil else { return }
        #endif

        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            self?.pushAuthorizationStatus = settings.authorizationStatus
        }
    }

    #if DEBUG
    func mockPushStatus(_ status: UNAuthorizationStatus) {
        pushAuthorizationStatus = status
    }
    #endif
}
