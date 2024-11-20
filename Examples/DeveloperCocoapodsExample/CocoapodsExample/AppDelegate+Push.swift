//
//  AppDelegate+Push.swift
//  AppcuesCocoapodsExample
//
//  Created by Matt on 2024-03-06.
//

// Disabled in favor of automatic configuration

/*
import Foundation
import UserNotifications
import AppcuesKit

extension AppDelegate: UNUserNotificationCenterDelegate {
    /// Call from `UIApplicationDelegate.application(_:didFinishLaunchingWithOptions:)`
    func setupPush(application: UIApplication) {
        // 1: Register to get a device token
        application.registerForRemoteNotifications()

        UNUserNotificationCenter.current().delegate = self
    }

    // 2: Pass device token to Appcues
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Appcues.shared.setPushToken(deviceToken)
    }

    // 3: Pass the user's response to a delivered notification to Appcues
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        if Appcues.shared.didReceiveNotification(response: response) {
            return
        }

        // Handle non-Appcues notifications
    }

    // 4: Configure handling for notifications that arrive while the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        if #available(iOS 14.0, *) {
            return [.banner, .list]
        } else {
            return .alert
        }
    }
}
*/
