//
//  UNUserNotificationCenter+AutoConfig.swift
//  AppcuesKit
//
//  Created by Matt on 2024-04-10.
//  Copyright © 2024 Appcues. All rights reserved.
//

import Foundation
import UserNotifications

// This is a placeholder delegate implementation in case there's no UNUserNotificationCenter.delegate set in the app
internal class AppcuesUNUserNotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
    static var shared = AppcuesUNUserNotificationCenterDelegate()
}

extension UNUserNotificationCenter {

    static func swizzleNotificationCenterGetDelegate() {
        // this will swap in a new getter for UNUserNotificationCenter.delegate - giving our code a chance to hook in
        let originalScrollViewDelegateSelector = #selector(getter: self.delegate)
        let swizzledScrollViewDelegateSelector = #selector(appcues__getNotificationCenterDelegate)

        guard let originalScrollViewMethod = class_getInstanceMethod(self, originalScrollViewDelegateSelector),
              let swizzledScrollViewMethod = class_getInstanceMethod(self, swizzledScrollViewDelegateSelector) else {
            return
        }

        method_exchangeImplementations(originalScrollViewMethod, swizzledScrollViewMethod)
    }

    // this is our custom getter logic for the UNUserNotificationCenter.delegate
    @objc
    private func appcues__getNotificationCenterDelegate() -> UNUserNotificationCenterDelegate? {
        let delegate: UNUserNotificationCenterDelegate

        // this call looks recursive, but it is not, it is calling the swapped implementation
        // to get the actual delegate value that has been assigned, if any - can be nil
        if let existingDelegate = appcues__getNotificationCenterDelegate() {
            delegate = existingDelegate
        } else {
            // if it is nil, then we assign our own delegate implementation so there is
            // something hooked in to listen to notifications
            delegate = AppcuesUNUserNotificationCenterDelegate.shared
            self.delegate = delegate
        }

        Swizzler.swizzle(
            targetInstance: delegate,
            targetSelector: NSSelectorFromString("userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:"),
            replacementOwner: UNUserNotificationCenter.self,
            placeholderSelector: #selector(appcues__placeholderUserNotificationCenterDidReceive),
            swizzleSelector: #selector(appcues__userNotificationCenterDidReceive)
        )

        Swizzler.swizzle(
            targetInstance: delegate,
            targetSelector: NSSelectorFromString("userNotificationCenter:willPresentNotification:withCompletionHandler:"),
            replacementOwner: UNUserNotificationCenter.self,
            placeholderSelector: #selector(appcues__placeholderUserNotificationCenterWillPresent),
            swizzleSelector: #selector(appcues__userNotificationCenterWillPresent)
        )

        return delegate
    }

    @objc
    func appcues__placeholderUserNotificationCenterDidReceive(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // this gives swizzling something to replace, if the existing delegate doesn't already
        // implement this function.
        completionHandler()
    }

    @objc
    func appcues__placeholderUserNotificationCenterWillPresent(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // this gives swizzling something to replace, if the existing delegate doesn't already
        // implement this function.
        completionHandler([])
    }

    @objc
    func appcues__userNotificationCenterDidReceive(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if ParsedNotification(userInfo: response.notification.request.content.userInfo) != nil {
            PushAutoConfig.didReceive(response, withCompletionHandler: completionHandler)
        } else {
            // Not an Appcues push, so pass to the original implementation
            appcues__userNotificationCenterDidReceive(center, didReceive: response, withCompletionHandler: completionHandler)
        }
    }

    @objc
    func appcues__userNotificationCenterWillPresent(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if let parsedNotification = ParsedNotification(userInfo: notification.request.content.userInfo) {
            PushAutoConfig.willPresent(parsedNotification, withCompletionHandler: completionHandler)
        } else {
            // Not an Appcues push, so pass to the original implementation
            appcues__userNotificationCenterWillPresent(center, willPresent: notification, withCompletionHandler: completionHandler)
        }
    }
}
