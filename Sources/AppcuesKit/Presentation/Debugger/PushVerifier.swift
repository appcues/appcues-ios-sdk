//
//  PushVerifier.swift
//  AppcuesKit
//
//  Created by Matt on 2024-03-08.
//  Copyright © 2024 Appcues. All rights reserved.
//

import UIKit
import Combine

@available(iOS 13.0, *)
internal class PushVerifier {
    enum ErrorMessage: CustomStringConvertible {
        case noToken
        case notAuthorized
        case permissionDenied
        case unexpectedStatus
        case noNotificationDelegate
        case noReceiveHandler
        case multipleCompletions
        case noSDKResponse

        // Verification flow errors
        case tokenMismatch
        case responseInitFail

        var description: String {
            switch self {
            case .noToken:
                return "Error 1: No push token registered with Appcues"
            case .notAuthorized:
                return "Error 2: Notification permissions not requested"
            case .permissionDenied:
                return "Error 3: Notification permissions denied"
            case .unexpectedStatus:
                return "Error 4: Unexpected notification permission status"
            case .noNotificationDelegate:
                return "Error 5: Notification delegate is not set"
            case .noReceiveHandler:
                return "Error 6: Receive handler not implemented"
            case .multipleCompletions:
                return "Error 7: Receive completion called too many times"
            case .noSDKResponse:
                return "Error 8: Receive response not passed to SDK"
            case .tokenMismatch:
                return "Error 10: Unexpected result"
            case .responseInitFail:
                return "Error 11: Unexpected result"
            }
        }
    }

    static let title = "Push Notifications Configured"

    private let config: Appcues.Config
    private let storage: DataStoring
    private let networking: Networking
    private let pushMonitor: PushMonitoring

    /// Unique value to pass through a deep link to verify handling.
    private var pushVerificationToken: String?

    private var errors: [ErrorMessage] = [] {
        didSet {
            if !errors.isEmpty {
                subject.send(
                    StatusItem(status: .unverified, title: PushVerifier.title, subtitle: errors.map(\.description).joined(separator: "\n"))
                )
            }
        }
    }

    private let subject = PassthroughSubject<StatusItem, Never>()
    var publisher: AnyPublisher<StatusItem, Never> { subject.eraseToAnyPublisher() }

    init(container: DIContainer) {
        self.config = container.resolve(Appcues.Config.self)
        self.storage = container.resolve(DataStoring.self)
        self.networking = container.resolve(Networking.self)
        self.pushMonitor = container.resolve(PushMonitoring.self)
    }

    func verifyPush(token: UUID = UUID()) {
        subject.send(StatusItem(status: .pending, title: PushVerifier.title, subtitle: nil))

        // If the previous verification attempt errored because notification permissions haven't been requested,
        // request them before trying again.
        if errors.contains(.notAuthorized) {
            errors = []
            requestPush()
            return
        }

        errors = []

        verifyDeviceConfiguration()
        verifyClientImplementation(token: token.uuidString)
    }

    func receivedVerification(token: String) {
        if token == pushVerificationToken {
            verifyServerComponents(token: token)
        } else {
            errors.append(.tokenMismatch)
        }

        pushVerificationToken = nil
    }

    private func requestPush() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { _, _ in
            self.pushMonitor.refreshPushStatus { _ in
                DispatchQueue.main.async {
                    self.verifyPush()
                }
            }
        }
    }

    private func verifyDeviceConfiguration() {
        if storage.pushToken == nil {
            errors.append(.noToken)
        }

        switch pushMonitor.pushAuthorizationStatus {
        case .notDetermined, .provisional:
            errors.append(.notAuthorized)
        case .denied:
            errors.append(.permissionDenied)
        case .authorized:
            break
        case .ephemeral:
            fallthrough
        @unknown default:
            errors.append(.unexpectedStatus)
        }
    }

    private func verifyClientImplementation(token: String) {
        let notificationCenter = UNUserNotificationCenter.current()
        guard let notificationDelegate = notificationCenter.delegate else {
            errors.append(.noNotificationDelegate)
            return
        }

        guard let receiveHandler = notificationDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:) else {
            errors.append(.noReceiveHandler)
            return
        }

        guard let mockResponse = UNNotificationResponse.mock(token: token) else {
            errors.append(.responseInitFail)
            return
        }

        pushVerificationToken = token
        var completionCount = 0
        receiveHandler(notificationCenter, mockResponse) { [weak self] in
            completionCount += 1
            if completionCount > 1 {
                self?.errors.append(.multipleCompletions)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // in a valid implementation pushVerificationToken will be nil by now
            // from receivedVerification(token:) being called from PushMonitor
            if self.pushVerificationToken != nil {
                self.errors.append(.noSDKResponse)
                self.pushVerificationToken = nil
            }
        }
    }

    private func verifyServerComponents(token: String) {
        // TODO: trigger remote call to verify E2E
        if errors.isEmpty {
            subject.send(StatusItem(status: .verified, title: PushVerifier.title))
        }
    }
}

private extension UNNotificationResponse {
    final class KeyedArchiver: NSKeyedArchiver {
        override func decodeObject(forKey _: String) -> Any { "" }

        deinit {
            // Avoid a console warning
            finishEncoding()
        }
    }

    static func mock(
        token: String,
        actionIdentifier: String = UNNotificationDefaultActionIdentifier
    ) -> UNNotificationResponse? {
        guard let response = UNNotificationResponse(coder: KeyedArchiver()),
              let notification = UNNotification(coder: KeyedArchiver()) else {
            return nil
        }

        let content = UNMutableNotificationContent()
        content.userInfo = [
            "_appcues_internal": true,
            "appcues_account_id": "",
            "appcues_user_id": "",
            "appcues_notification_id": token
        ]

        let request = UNNotificationRequest(
            identifier: "",
            content: content,
            trigger: nil
        )
        notification.setValue(request, forKey: "request")

        response.setValue(notification, forKey: "notification")
        response.setValue(actionIdentifier, forKey: "actionIdentifier")

        return response
    }
}
