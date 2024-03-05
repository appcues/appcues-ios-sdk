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
    var pushPrimerEligible: Bool { get }

    func refreshPushStatus(completion: ((UNAuthorizationStatus) -> Void)?)

    // Using `userInfo` as a parameter to be able to mock notification data.
    func didReceiveNotification(userInfo: [AnyHashable: Any], completionHandler: @escaping () -> Void) -> Bool
}

internal class PushMonitor: PushMonitoring {

    private weak var appcues: Appcues?
    private let storage: DataStoring

    private var pushAuthorizationStatus: UNAuthorizationStatus = .notDetermined

    var pushEnabled: Bool {
        pushAuthorizationStatus == .authorized && storage.pushToken != nil
    }

    var pushBackgroundEnabled: Bool {
        storage.pushToken != nil
    }

    var pushPrimerEligible: Bool {
        pushAuthorizationStatus == .notDetermined
    }

    init(container: DIContainer) {
        self.appcues = container.owner
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

    func refreshPushStatus(completion: ((UNAuthorizationStatus) -> Void)? = nil) {
        // Skip call to UNUserNotificationCenter.current() in tests to avoid crashing in package tests
        #if DEBUG
        guard ProcessInfo.processInfo.environment["XCTestBundlePath"] == nil else {
            completion?(pushAuthorizationStatus)
            return
        }
        #endif

        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            self?.pushAuthorizationStatus = settings.authorizationStatus
            completion?(settings.authorizationStatus)
        }
    }

    // `completionHandler` should be called iff the function returns true.
    func didReceiveNotification(userInfo: [AnyHashable: Any], completionHandler: @escaping () -> Void) -> Bool {
        guard let parsedNotification = ParsedNotification(userInfo: userInfo) else {
            // Not an Appcues push
            return false
        }

        guard let appcues = appcues else {
            return false
        }

        // If there's a user ID mismatch, don't do anything with the notification
        guard parsedNotification.userID == storage.userID else {
            completionHandler()
            return true
        }

        // If no session, start one for the user in the notification
        if !appcues.isActive {
            storage.userID = parsedNotification.userID
            storage.isAnonymous = false
        }

        let analyticsPublisher = appcues.container.resolve(AnalyticsPublishing.self)
        analyticsPublisher.publish(TrackingUpdate(
            type: .event(name: Events.Push.pushOpened.rawValue, interactive: false),
            properties: [
                "notification_id": parsedNotification.notificationID
            ],
            isInternal: true
        ))

        if #available(iOS 13.0, *) {
            var actions: [AppcuesExperienceAction] = []

            if let deepLinkURL = parsedNotification.deepLinkURL {
                actions.append(AppcuesLinkAction(appcues: appcues, url: deepLinkURL))
            }

            if let experienceID = parsedNotification.experienceID {
                actions.append(AppcuesLaunchExperienceAction(appcues: appcues, experienceID: experienceID, trigger: .push))
            }

            let actionRegistry = appcues.container.resolve(ActionRegistry.self)
            actionRegistry.enqueue(actionInstances: actions, completion: completionHandler)
        } else {
            completionHandler()
        }

        return true
    }

    #if DEBUG
    func mockPushStatus(_ status: UNAuthorizationStatus) {
        pushAuthorizationStatus = status
    }
    #endif
}
