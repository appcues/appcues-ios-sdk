//
//  PushVerifier.swift
//  AppcuesKit
//
//  Created by Matt on 2024-03-08.
//  Copyright © 2024 Appcues. All rights reserved.
//

import UIKit
import Combine

// For mock objects
private final class KeyedArchiver: NSKeyedArchiver {
    override func decodeObject(forKey _: String) -> Any { "" }

    deinit {
        // Avoid a console warning
        finishEncoding()
    }
}

@available(iOS 13.0, *)
internal class PushVerifier {
    enum ErrorMessage: Equatable, CustomStringConvertible {
        case noPushEnvironment(String)
        case noToken
        case notAuthorized
        case permissionDenied
        case unexpectedStatus
        case noNotificationDelegate
        case noReceiveHandler
        case multipleCompletions
        case noSDKResponse
        case noForegroundPresentationHandler
        case noForegroundPresentationOption

        case serverError(Int, String?)

        // Verification flow errors
        case tokenMismatch
        case responseInitFail

        var description: String {
            switch self {
            case .noPushEnvironment(let error):
                return "Error 0: Could not determine push environment\n(\(error))"
            case .noToken:
                return "Error 1: No push token registered with Appcues"
            case .notAuthorized:
                return "Error 2: Notification permissions not requested"
            case .permissionDenied:
                return "Error 3: Notification permissions denied. Tap to open system settings"
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
            case .noForegroundPresentationHandler:
                return "Error 9: Foreground presentation handler not implemented"
            case .noForegroundPresentationOption:
                return "Note: Application is not configured to display foreground notifications"
            case let .serverError(statusCode, error):
                return "Error \(statusCode): \(error ?? "Unexpected server error")"
            case .tokenMismatch:
                return "Error 100: Unexpected result"
            case .responseInitFail:
                return "Error 101: Unexpected result"
            }
        }

        var isWarning: Bool {
            self == .noForegroundPresentationOption
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
                let status = errors.allSatisfy { $0.isWarning } ? StatusItem.Status.info : .unverified
                subject.send(
                    StatusItem(status: status, title: PushVerifier.title, subtitle: errors.map(\.description).joined(separator: "\n"))
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

        if errors.contains(.permissionDenied), let settingsURL = URL(string: "app-settings://") {
            errors = []
            UIApplication.shared.open(settingsURL)
            return
        }

        errors = []

        verifyDeviceConfiguration()
        verifyClientImplementation(token: token.uuidString)
    }

    func receivedVerification(token: String) {
        if token != pushVerificationToken {
            errors.append(.tokenMismatch)
        }

        if errors.isEmpty {
            verifyServerComponents(token: token)
        }

        pushVerificationToken = nil
    }

    private func requestPush() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { _, _ in
            self.pushMonitor.refreshPushStatus(publishChange: true) { _ in
                DispatchQueue.main.async {
                    self.verifyPush()
                }
            }
        }
    }

    private func verifyDeviceConfiguration() {
        if case .unknown(let reason) = pushMonitor.pushEnvironment {
            errors.append(.noPushEnvironment(reason.description))
        }

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

        verifyReceiveHandler(
            token: token,
            notificationCenter: notificationCenter,
            notificationDelegate: notificationDelegate
        )

        verifyForegroundPresentationHandler(
            token: token,
            notificationCenter: notificationCenter,
            notificationDelegate: notificationDelegate
        )
    }

    private func verifyReceiveHandler(
        token: String,
        notificationCenter: UNUserNotificationCenter,
        notificationDelegate: UNUserNotificationCenterDelegate
    ) {
        guard let receiveHandler = notificationDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:) else {
            errors.append(.noReceiveHandler)
            return
        }

        guard let mockResponse = UNNotificationResponse.mock(token: token, config: config) else {
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

    private func verifyForegroundPresentationHandler(
        token: String,
        notificationCenter: UNUserNotificationCenter,
        notificationDelegate: UNUserNotificationCenterDelegate
    ) {
        guard let presentationHandler = notificationDelegate.userNotificationCenter(_:willPresent:withCompletionHandler:) else {
            errors.append(.noForegroundPresentationHandler)
            return
        }

        guard let mockNotification = UNNotification.mock(token: token, config: config) else {
            errors.append(.responseInitFail)
            return
        }

        presentationHandler(notificationCenter, mockNotification) { [weak self] options in
            if #available(iOS 14.0, *) {
                if !options.contains(.banner) {
                    self?.errors.append(.noForegroundPresentationOption)
                }
            } else {
                if !options.contains(.alert) {
                    self?.errors.append(.noForegroundPresentationOption)
                }
            }
        }
    }

    private func verifyServerComponents(token: String) {
        let body = PushRequest(
            deviceID: storage.deviceID
        )

        let data = try? NetworkClient.encoder.encode(body)

        networking.post(
            to: APIEndpoint.pushTest,
            authorization: nil,
            body: data,
            requestId: nil
        ) { [weak self] (result: Result<PushTestResponse, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    if self?.errors.isEmpty == true {
                        self?.subject.send(StatusItem(status: .verified, title: PushVerifier.title))
                    }
                case .failure(let error):
                    switch error {
                    case let NetworkingError.nonSuccessfulStatusCode(statusCode, data?):
                        if let errorModel = try? NetworkClient.decoder.decode(PushTestError.self, from: data) {
                            self?.errors.append(.serverError(statusCode, errorModel.error))
                        } else {
                            self?.errors.append(.serverError(statusCode, nil))
                        }
                    default:
                        self?.errors.append(.serverError(0, nil))
                    }
                }
            }
        }
    }
}

@available(iOS 13.0, *)
private extension PushVerifier {
    struct PushTestResponse: Decodable {
        let ok: Bool
    }

    struct PushTestError: Decodable {
        let error: String
    }
}

private extension UNNotificationResponse {
    static func mock(
        token: String,
        config: Appcues.Config,
        actionIdentifier: String = UNNotificationDefaultActionIdentifier
    ) -> UNNotificationResponse? {
        guard let response = UNNotificationResponse(coder: KeyedArchiver()),
              let notification = UNNotification.mock(token: token, config: config) else {
            return nil
        }

        response.setValue(notification, forKey: "notification")
        response.setValue(actionIdentifier, forKey: "actionIdentifier")

        return response
    }
}

private extension UNNotification {
    static func mock(
        token: String,
        config: Appcues.Config,
        actionIdentifier: String = UNNotificationDefaultActionIdentifier
    ) -> UNNotification? {
        guard let notification = UNNotification(coder: KeyedArchiver()) else {
            return nil
        }

        let content = UNMutableNotificationContent()
        content.userInfo = [
            "_appcues_internal": true,
            "appcues_account_id": config.accountID,
            "appcues_app_id": config.applicationID,
            "appcues_user_id": "",
            "appcues_notification_id": token
        ]

        let request = UNNotificationRequest(
            identifier: "",
            content: content,
            trigger: nil
        )
        notification.setValue(request, forKey: "request")

        return notification
    }
}
