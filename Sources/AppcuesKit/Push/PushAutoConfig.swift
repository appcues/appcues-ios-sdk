//
//  PushAutoConfig.swift
//  AppcuesKit
//
//  Created by Matt on 2024-04-15.
//  Copyright © 2024 Appcues. All rights reserved.
//

import UIKit

internal enum PushAutoConfig {
    // This is an array to support the (rare) case of multiple SDK instances supporting push
    private static var pushMonitors: [WeakPushMonitoring] = []

    private static var receivedToken: Data?
    private static var receivedUnhandledResponse: UNNotificationResponse?

    static func register(observer: PushMonitoring) {
        pushMonitors.append(WeakPushMonitoring(observer))

        // If a push token was obtained before the instance was registered, set it
        if let receivedToken = receivedToken {
            observer.setPushToken(receivedToken)
        }

        // If an Appcues push notification was opened and unhandled before the instance was registered,
        // see if this new instance can handle it
        if let response = receivedUnhandledResponse {
            let didHandle = observer.didReceiveNotification(response: response)
            if didHandle {
                receivedUnhandledResponse = nil
            }
        }
    }

    static func remove(observer: PushMonitoring) {
        pushMonitors.removeAll { $0.value == nil || $0.value === observer }
    }

    static func configureAutomatically() {
        UIApplication.swizzleDidRegisterForDeviceToken()
        UIApplication.shared.registerForRemoteNotifications()

        UNUserNotificationCenter.swizzleNotificationCenterGetDelegate()
    }

    static func didRegister(deviceToken: Data) {
        // Save device token for any future PushMonitor instances
        receivedToken = deviceToken

        // Pass device token to all observing PushMonitor instances
        pushMonitors.forEach { weakPushMonitor in
            if let pushMonitor = weakPushMonitor.value {
                pushMonitor.setPushToken(deviceToken)
            }
        }
    }

    // Shared instance is called from the swizzled method
    static func didReceive(
        _ response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Stop at the first PushMonitor that successfully handles the notification
        let didHandleResponse = pushMonitors.contains { weakPushMonitor in
            guard let pushMonitor = weakPushMonitor.value else { return false }
            return pushMonitor.didReceiveNotification(response: response)
        }

        // Clear the existing value if a newer response was handled, or
        // save unhandled response for any future PushMonitor instances
        receivedUnhandledResponse = didHandleResponse ? nil : response

        completionHandler()
    }

    // Shared instance is called from the swizzled method
    static func willPresent(
        _ parsedNotification: ParsedNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Behavior for all Appcues notification
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .list])
        } else {
            completionHandler(.alert)
        }
    }
}

extension PushAutoConfig {
    class WeakPushMonitoring {
        weak var value: PushMonitoring?

        init (_ wrapping: PushMonitoring) { self.value = wrapping }
    }
}
