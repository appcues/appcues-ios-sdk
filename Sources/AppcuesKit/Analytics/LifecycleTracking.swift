//
//  LifecycleTracking.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/29/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation
import UIKit

internal class LifecycleTracking {

    enum LifecycleEvents: String {
        case applicationInstalled = "appcues:application_installed"
        case applicationOpened = "appcues:application_opened"
        case applicationUpdated = "appcues:application_updated"
        case applicationBackgrounded = "appcues:application_backgrounded"
    }

    private let publisher: AnalyticsPublisher

    private var wasBackgrounded = false

    var launchType: LaunchType = .open

    init(container: DIContainer) {
        self.publisher = container.resolve(AnalyticsPublisher.self)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didFinishLaunching),
                                               name: UIApplication.didFinishLaunchingNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }

    @objc
    func didFinishLaunching(notification: Notification) {
        let launchOptions = notification.userInfo as? [UIApplication.LaunchOptionsKey: Any]
        publisher.track(name: launchType.lifecycleEvent.rawValue, properties: [
            "from_background": false,
            "referring_application": launchOptions?[UIApplication.LaunchOptionsKey.sourceApplication] ?? "",
            "url": launchOptions?[UIApplication.LaunchOptionsKey.url] ?? ""
        ])
    }

    @objc
    func applicationWillEnterForeground(notification: Notification) {
        guard wasBackgrounded else { return }
        wasBackgrounded = false
        publisher.track(name: LifecycleEvents.applicationOpened.rawValue,
                        properties: [
                            "from_background": true
                        ])
    }

    @objc
    func didEnterBackground(notification: Notification) {
        wasBackgrounded = true
        publisher.track(name: LifecycleEvents.applicationBackgrounded.rawValue)
    }
}

private extension LaunchType {
    var lifecycleEvent: LifecycleTracking.LifecycleEvents {
        switch self {
        case .install:
            return .applicationInstalled
        case .open:
            return .applicationOpened
        case .update:
            return .applicationUpdated
        }
    }
}
