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

    static func register(observer: PushMonitoring) {
        pushMonitors.append(WeakPushMonitoring(observer))
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
        _ = pushMonitors.first { weakPushMonitor in
            if let pushMonitor = weakPushMonitor.value {
                return pushMonitor.didReceiveNotification(response: response, completionHandler: completionHandler)
            }
            return false
        }
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
