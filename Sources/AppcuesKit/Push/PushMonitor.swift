//
//  PushMonitor.swift
//  AppcuesKit
//
//  Created by Matt on 2024-02-22.
//  Copyright © 2024 Appcues. All rights reserved.
//

import UIKit

internal protocol PushMonitoring: AnyObject {
    var pushAuthorizationStatus: UNAuthorizationStatus { get }
    var pushEnabled: Bool { get }
    var pushBackgroundEnabled: Bool { get }
    var pushPrimerEligible: Bool { get }

    func refreshPushStatus(publishChange: Bool, completion: ((UNAuthorizationStatus) -> Void)?)

    func didReceiveNotification(response: UNNotificationResponse, completionHandler: @escaping () -> Void) -> Bool
    @discardableResult
    func attemptDeferredNotificationResponse() -> Bool
}

internal class PushMonitor: PushMonitoring {

    private weak var appcues: Appcues?
    private let config: Appcues.Config
    private let storage: DataStoring
    private let analyticsPublisher: AnalyticsPublishing

    private(set) var pushAuthorizationStatus: UNAuthorizationStatus = .notDetermined

    var pushEnabled: Bool {
        pushAuthorizationStatus == .authorized && storage.pushToken != nil
    }

    var pushBackgroundEnabled: Bool {
        storage.pushToken != nil
    }

    var pushPrimerEligible: Bool {
        pushAuthorizationStatus == .notDetermined
    }

    private var deferredNotification: ParsedNotification?

    init(container: DIContainer) {
        self.appcues = container.owner
        self.config = container.resolve(Appcues.Config.self)
        self.storage = container.resolve(DataStoring.self)
        self.analyticsPublisher = container.resolve(AnalyticsPublishing.self)

        refreshPushStatus(publishChange: false)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc
    private func applicationWillEnterForeground(notification: Notification) {
        refreshPushStatus(publishChange: true)
    }

    func refreshPushStatus(publishChange: Bool, completion: ((UNAuthorizationStatus) -> Void)? = nil) {
        // Skip call to UNUserNotificationCenter.current() in tests to avoid crashing in package tests
        #if DEBUG
        guard ProcessInfo.processInfo.environment["XCTestBundlePath"] == nil else {
            completion?(pushAuthorizationStatus)
            return
        }
        #endif

        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            let shouldPublish = publishChange && self?.pushAuthorizationStatus != settings.authorizationStatus
            self?.pushAuthorizationStatus = settings.authorizationStatus

            if shouldPublish {
                self?.analyticsPublisher.publish(TrackingUpdate(
                    type: .event(name: Events.Device.deviceUpdated.rawValue, interactive: false),
                    isInternal: true
                ))
            }

            completion?(settings.authorizationStatus)
        }
    }

    // `completionHandler` should be called iff the function returns true.
    func didReceiveNotification(response: UNNotificationResponse, completionHandler: @escaping () -> Void) -> Bool {
        let userInfo = response.notification.request.content.userInfo

        config.logger.info("Push response received:\n%{private}@", userInfo.description)

        guard let parsedNotification = ParsedNotification(userInfo: userInfo),
              parsedNotification.accountID == config.accountID,
              parsedNotification.applicationID == config.applicationID else {
            // Not an Appcues push
            return false
        }

        guard let appcues = appcues else {
            return false
        }

        guard !parsedNotification.isInternal else {
            // This is a synthetic notification response from PushVerifier.
            if #available(iOS 13.0, *) {
                let pushVerifier = appcues.container.resolve(PushVerifier.self)
                pushVerifier.receivedVerification(token: parsedNotification.notificationID)
            }
            completionHandler()
            return true
        }

        // If there's no active session store the notification for potential handling after the next user is identified
        guard appcues.isActive else {
            deferredNotification = parsedNotification

            completionHandler()
            return true
        }

        // If there's an active session and a user ID mismatch, don't do anything with the notification
        guard parsedNotification.userID == storage.userID else {
            completionHandler()
            return true
        }

        executeNotificationResponse(
            appcues: appcues,
            parsedNotification: parsedNotification,
            completionHandler: completionHandler
        )

        return true
    }

    @discardableResult
    func attemptDeferredNotificationResponse() -> Bool {
        guard let parsedNotification = deferredNotification, let appcues = appcues else { return false }

        defer {
            deferredNotification = nil
        }

        guard parsedNotification.userID == storage.userID else {
            config.logger.info("Deferred notification response skipped")
            return false
        }

        executeNotificationResponse(appcues: appcues, parsedNotification: parsedNotification) {}

        return true
    }

    private func executeNotificationResponse(
        appcues: Appcues,
        parsedNotification: ParsedNotification,
        completionHandler: @escaping () -> Void
    ) {
        if !parsedNotification.isTest {
            analyticsPublisher.publish(TrackingUpdate(
                type: .event(name: Events.Push.pushOpened.rawValue, interactive: false),
                properties: [
                    "notification_id": parsedNotification.notificationID,
                    "workflow_id": parsedNotification.workflowID,
                    "workflow_task_id": parsedNotification.workflowTaskID,
                    "device_id": storage.deviceID
                ].compactMapValues { $0 },
                isInternal: true
            ))
        }

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
    }

    #if DEBUG
    func mockPushStatus(_ status: UNAuthorizationStatus) {
        pushAuthorizationStatus = status
    }
    #endif
}
