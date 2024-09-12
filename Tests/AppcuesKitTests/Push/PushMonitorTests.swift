//
//  PushMonitorTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2024-02-26.
//  Copyright © 2024 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class PushMonitorTests: XCTestCase {

    var pushMonitor: PushMonitor!
    var appcues: MockAppcues!

    override func setUp() {
        let config = Appcues.Config(accountID: "00000", applicationID: "<app-id>")
        appcues = MockAppcues(config: config)
        pushMonitor = PushMonitor(container: appcues.container)
    }

    func testNoTokenNotAuthorized() throws {
        // Arrange
        appcues.storage.pushToken = nil
        pushMonitor.mockPushStatus(.denied)

        // Assert
        XCTAssertFalse(pushMonitor.pushEnabled)
        XCTAssertFalse(pushMonitor.pushBackgroundEnabled)
        XCTAssertFalse(pushMonitor.pushPrimerEligible)
    }

    func testNoTokenAuthorized() throws {
        // Arrange
        appcues.storage.pushToken = nil
        pushMonitor.mockPushStatus(.authorized)

        // Assert
        XCTAssertFalse(pushMonitor.pushEnabled)
        XCTAssertFalse(pushMonitor.pushBackgroundEnabled)
        XCTAssertFalse(pushMonitor.pushPrimerEligible)
    }

    func testTokenNotAuthorized() throws {
        // Arrange
        appcues.storage.pushToken = "<some-token>"
        pushMonitor.mockPushStatus(.denied)

        // Assert
        XCTAssertFalse(pushMonitor.pushEnabled)
        XCTAssertTrue(pushMonitor.pushBackgroundEnabled)
        XCTAssertFalse(pushMonitor.pushPrimerEligible)
    }

    func testTokenAuthorized() throws {
        // Arrange
        appcues.storage.pushToken = "<some-token>"
        pushMonitor.mockPushStatus(.authorized)

        // Assert
        XCTAssertTrue(pushMonitor.pushEnabled)
        XCTAssertTrue(pushMonitor.pushBackgroundEnabled)
        XCTAssertFalse(pushMonitor.pushPrimerEligible)
    }

    func testPrimerEligible() throws {
        appcues.storage.pushToken = "<some-token>"
        pushMonitor.mockPushStatus(.notDetermined)

        // Assert
        XCTAssertFalse(pushMonitor.pushEnabled)
        XCTAssertTrue(pushMonitor.pushBackgroundEnabled)
        XCTAssertTrue(pushMonitor.pushPrimerEligible)
    }

    // MARK: Set Token
    func testSetPushToken() throws {
        // Arrange
        let token = "some-token".data(using: .utf8)

        // Act
        pushMonitor.setPushToken(token)

        // Assert
        XCTAssertEqual(appcues.storage.pushToken, "736f6d652d746f6b656e")
    }

    func testSetPushTokenActiveSession() throws {
        // Arrange
        appcues.sessionID = UUID()
        let token = "some-token".data(using: .utf8)
        let eventExpectation = expectation(description: "Device event logged")
        appcues.analyticsPublisher.onPublish = { trackingUpdate in
            XCTAssertEqual(trackingUpdate.type, .event(name: Events.Device.deviceUpdated.rawValue, interactive: true))
            XCTAssertNil(trackingUpdate.properties)
            eventExpectation.fulfill()
        }

        // Act
        pushMonitor.setPushToken(token)

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertEqual(appcues.storage.pushToken, "736f6d652d746f6b656e")
    }

    func testSetPushTokenNoAnalyticsWhenSameValue() throws {
        // Arrange
        appcues.storage.pushToken = "736f6d652d746f6b656e"
        appcues.sessionID = UUID()
        let token = "some-token".data(using: .utf8)
        let eventExpectation = expectation(description: "Device event logged")
        eventExpectation.isInverted = true
        appcues.analyticsPublisher.onPublish = { trackingUpdate in
            eventExpectation.fulfill()
        }

        // Act
        pushMonitor.setPushToken(token)

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertEqual(appcues.storage.pushToken, "736f6d652d746f6b656e")
    }
    // MARK: Receive Handler

    func testReceiveActiveSession() throws {
        // Arrange
        let userInfo = Dictionary<AnyHashable, Any>.appcuesPush
        let response = try XCTUnwrap(UNNotificationResponse.mock(userInfo: userInfo))

        let analyticsExpectation = expectation(description: "push open event")
        let completionExpectation = expectation(description: "completion called")

        let completion = {
            completionExpectation.fulfill()
        }

        appcues.analyticsPublisher.onPublish = { update in
            XCTAssertEqual(update.type, .event(name: Events.Push.pushOpened.rawValue, interactive: false))
            analyticsExpectation.fulfill()
        }

        appcues.storage.userID = "default-00000"
        appcues.sessionID = UUID()

        // Act
        let result = pushMonitor.didReceiveNotification(response: response, completionHandler: completion)

        // Assert
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(result)
    }

    func testReceiveActions() throws {
        // Arrange
        var userInfo = Dictionary<AnyHashable, Any>.appcuesPush
        userInfo["appcues_deep_link_url"] = "app://some-link"
        userInfo["appcues_experience_id"] = "<some-experience>"
        let response = try XCTUnwrap(UNNotificationResponse.mock(userInfo: userInfo))

        let analyticsExpectation = expectation(description: "push open event")
        let linkCompletionExpectation = expectation(description: "link opened")
        let loadCompletionExpectation = expectation(description: "experience loaded")
        let completionExpectation = expectation(description: "completion called")

        appcues.analyticsPublisher.onPublish = { update in
            XCTAssertEqual(update.type, .event(name: Events.Push.pushOpened.rawValue, interactive: false))
            [
                "push_notification_id": "DEADBEEF-0000-0000-0000-000000000001",
                "push_notification_version": 123,
                "workflow_id": "DEADBEEF-0000-0000-0000-000000000002",
                "workflow_version": 456,
                "workflow_task_id": "DEADBEEF-0000-0000-0000-000000000003",
                "device_id": "device-id"
            ].verifyPropertiesMatch(update.properties)

            analyticsExpectation.fulfill()
        }

        let navigationDelegate = MockNavigationDelegate()
        appcues.navigationDelegate = navigationDelegate
        navigationDelegate.onNavigate = { url, external in
            XCTAssertEqual(url.absoluteString, "app://some-link")
            linkCompletionExpectation.fulfill()
        }

        appcues.contentLoader.onLoad = { experienceID, published, trigger, completion in
            XCTAssertEqual(experienceID, "<some-experience>")
            XCTAssertTrue(published)
            XCTAssertEqual(trigger, .pushNotification(notificationID: "DEADBEEF-0000-0000-0000-000000000001"))
            loadCompletionExpectation.fulfill()
            completion?(.success(()))
        }

        let completion = {
            completionExpectation.fulfill()
        }

        appcues.storage.userID = "default-00000"
        appcues.sessionID = UUID()

        // Act
        let result = pushMonitor.didReceiveNotification(response: response, completionHandler: completion)

        // Assert
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(result)
    }

    func testReceiveMalformed() throws {
        // Arrange
        let userInfo = Dictionary<AnyHashable, Any>.basicPush
        let response = try XCTUnwrap(UNNotificationResponse.mock(userInfo: userInfo))

        let completion = {
            XCTFail("completion should not be called")
        }

        // Act
        let result = pushMonitor.didReceiveNotification(response: response, completionHandler: completion)

        // Assert
        XCTAssertFalse(result)
    }

    func testReceiveNoAppcues() throws {
        // Arrange
        let userInfo = Dictionary<AnyHashable, Any>.appcuesPush
        let response = try XCTUnwrap(UNNotificationResponse.mock(userInfo: userInfo))

        let completion = {
            XCTFail("completion should not be called")
        }
        appcues = nil

        // Act
        let result = pushMonitor.didReceiveNotification(response: response, completionHandler: completion)

        // Assert
        XCTAssertFalse(result)
    }

    func testReceiveUserIdMismatch() throws {
        // Arrange
        let userInfo = Dictionary<AnyHashable, Any>.appcuesPush
        let response = try XCTUnwrap(UNNotificationResponse.mock(userInfo: userInfo))

        let completionExpectation = expectation(description: "completion called")

        let completion = {
            completionExpectation.fulfill()
        }

        appcues.analyticsPublisher.onPublish = { update in
            XCTFail("no push opened analytic expected")
        }

        appcues.storage.userID = "some-user"
        appcues.sessionID = UUID()

        // Act
        let result = pushMonitor.didReceiveNotification(response: response, completionHandler: completion)

        // Assert
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(result)
    }

    func testReceiveNoSession() throws {
        // Arrange
        let userInfo = Dictionary<AnyHashable, Any>.appcuesPush
        let response = try XCTUnwrap(UNNotificationResponse.mock(userInfo: userInfo))

        let completionExpectation = expectation(description: "completion called")

        appcues.analyticsPublisher.onPublish = { update in
            XCTFail("no push opened analytic expected")
        }

        let completion = {
            completionExpectation.fulfill()
        }

        appcues.storage.userID = "default-00000"
        appcues.sessionID = nil

        // Act
        let result = pushMonitor.didReceiveNotification(response: response, completionHandler: completion)

        // Assert
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(result)
    }

    func testReceiveTestPush() throws {
        // Arrange
        var userInfo = Dictionary<AnyHashable, Any>.appcuesPush
        userInfo["appcues_test"] = "true"
        let response = try XCTUnwrap(UNNotificationResponse.mock(userInfo: userInfo))

        let completionExpectation = expectation(description: "completion called")

        appcues.analyticsPublisher.onPublish = { update in
            XCTFail("no push opened analytic expected for test push")
        }

        let completion = {
            completionExpectation.fulfill()
        }

        appcues.storage.userID = "default-00000"
        appcues.sessionID = UUID()

        // Act
        let result = pushMonitor.didReceiveNotification(response: response, completionHandler: completion)

        // Assert
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(result)
    }

    func testDeferredHandlingMatchingUser() throws {
        // Arrange
        var userInfo = Dictionary<AnyHashable, Any>.appcuesPush
        userInfo["appcues_deep_link_url"] = "app://some-link"
        userInfo["appcues_experience_id"] = "<some-experience>"
        let response = try XCTUnwrap(UNNotificationResponse.mock(userInfo: userInfo))

        let analyticsExpectation = expectation(description: "push open event")
        let linkCompletionExpectation = expectation(description: "link opened")
        let loadCompletionExpectation = expectation(description: "experience loaded")
        let completionExpectation = expectation(description: "completion called")

        let completion = {
            completionExpectation.fulfill()
        }

        appcues.storage.userID = "default-00000"
        appcues.sessionID = nil

        appcues.analyticsPublisher.onPublish = { update in
            XCTFail("no push opened analytic expected from the initial receive")
        }

        // Store a deferred notification
        let result = pushMonitor.didReceiveNotification(response: response, completionHandler: completion)

        appcues.analyticsPublisher.onPublish = { update in
            XCTAssertEqual(update.type, .event(name: Events.Push.pushOpened.rawValue, interactive: false))
            analyticsExpectation.fulfill()
        }

        let navigationDelegate = MockNavigationDelegate()
        appcues.navigationDelegate = navigationDelegate
        navigationDelegate.onNavigate = { url, external in
            XCTAssertEqual(url.absoluteString, "app://some-link")
            linkCompletionExpectation.fulfill()
        }

        appcues.contentLoader.onLoad = { experienceID, published, trigger, completion in
            XCTAssertEqual(experienceID, "<some-experience>")
            XCTAssertTrue(published)
            XCTAssertEqual(trigger, .pushNotification(notificationID: "DEADBEEF-0000-0000-0000-000000000001"))
            loadCompletionExpectation.fulfill()
            completion?(.success(()))
        }

        // Act
        let didHandleDeferred = pushMonitor.attemptDeferredNotificationResponse()

        // Assert
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(result)
        XCTAssertTrue(didHandleDeferred)
    }

    func testDeferredHandlingNonMatchingUser() throws {
        // Arrange
        var userInfo = Dictionary<AnyHashable, Any>.appcuesPush
        userInfo["appcues_deep_link_url"] = "app://some-link"
        userInfo["appcues_experience_id"] = "<some-experience>"
        let response = try XCTUnwrap(UNNotificationResponse.mock(userInfo: userInfo))

        let completionExpectation = expectation(description: "completion called")

        appcues.analyticsPublisher.onPublish = { update in
            XCTFail("no push opened analytic expected")
        }

        let completion = {
            completionExpectation.fulfill()
        }

        appcues.storage.userID = "non-matching-user"
        appcues.sessionID = nil

        // Store a deferred notification
        let result = pushMonitor.didReceiveNotification(response: response, completionHandler: completion)

        // Act
        let didHandleDeferred = pushMonitor.attemptDeferredNotificationResponse()

        // Assert
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(result)
        XCTAssertFalse(didHandleDeferred)
    }

    func testNoDeferredMessage() throws {
        // Act
        let didHandleDeferred = pushMonitor.attemptDeferredNotificationResponse()

        // Assert
        XCTAssertFalse(didHandleDeferred)
    }

}

extension Dictionary where Key == AnyHashable, Value == Any {
    static var basicPush: Self {
        [
            "aps": [
                "alert": [
                    "title": "Hello world",
                    "body": "Notification from appcues"
                ]
            ]
        ]
    }

    static var appcuesPush: Self {
        [
            "aps": [
                "alert": [
                    "title": "Hello world",
                    "body": "Notification from appcues"
                ]
            ],
            "appcues_account_id": "00000",
            "appcues_app_id": "<app-id>",
            "appcues_user_id": "default-00000",
            "appcues_notification_id": "DEADBEEF-0000-0000-0000-000000000001",
            "appcues_notification_version": 123,
            "appcues_workflow_id": "DEADBEEF-0000-0000-0000-000000000002",
            "appcues_workflow_task_id": "DEADBEEF-0000-0000-0000-000000000003",
            "appcues_workflow_version": 456,
        ]
    }
}

private class MockNavigationDelegate: AppcuesNavigationDelegate {
    var onNavigate: ((URL, Bool) -> Void)?
    func navigate(to url: URL, openExternally: Bool, completion: @escaping (Bool) -> Void) {
        onNavigate?(url, openExternally)
        completion(true)
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
        userInfo: [AnyHashable: Any],
        actionIdentifier: String = UNNotificationDefaultActionIdentifier
    ) -> UNNotificationResponse? {
        guard let response = UNNotificationResponse(coder: KeyedArchiver()),
              let notification = UNNotification(coder: KeyedArchiver()) else {
            return nil
        }

        let content = UNMutableNotificationContent()
        content.userInfo = userInfo

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
