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
        let config = Appcues.Config(accountID: "00000", applicationID: "abc")
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

    // MARK: Receive Handler

    func testReceiveActiveSession() throws {
        // Arrange
        let userInfo = Dictionary<AnyHashable, Any>.appcuesPush

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
        let result = pushMonitor.didReceiveNotification(userInfo: userInfo, completionHandler: completion)

        // Assert
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(result)
    }

    func testReceiveActions() throws {
        // Arrange
        var userInfo = Dictionary<AnyHashable, Any>.appcuesPush
        userInfo["appcues_deep_link_url"] = "app://some-link"
        userInfo["appcues_experience_id"] = "<some-experience>"

        let analyticsExpectation = expectation(description: "push open event")
        let linkCompletionExpectation = expectation(description: "link opened")
        let loadCompletionExpectation = expectation(description: "experience loaded")
        let completionExpectation = expectation(description: "completion called")

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

        appcues.experienceLoader.onLoad = { experienceID, published, trigger, completion in
            XCTAssertEqual(experienceID, "<some-experience>")
            XCTAssertTrue(published)
            XCTAssertEqual(trigger, .push)
            loadCompletionExpectation.fulfill()
            completion?(.success(()))
        }

        let completion = {
            completionExpectation.fulfill()
        }

        appcues.storage.userID = "default-00000"
        appcues.sessionID = UUID()

        // Act
        let result = pushMonitor.didReceiveNotification(userInfo: userInfo, completionHandler: completion)

        // Assert
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(result)
    }

    func testReceiveMalformed() throws {
        // Arrange
        let userInfo = Dictionary<AnyHashable, Any>.basicPush

        let completion = {
            XCTFail("completion should not be called")
        }

        // Act
        let result = pushMonitor.didReceiveNotification(userInfo: userInfo, completionHandler: completion)

        // Assert
        XCTAssertFalse(result)
    }

    func testReceiveNoAppcues() throws {
        // Arrange
        let userInfo = Dictionary<AnyHashable, Any>.appcuesPush

        let completion = {
            XCTFail("completion should not be called")
        }
        appcues = nil

        // Act
        let result = pushMonitor.didReceiveNotification(userInfo: userInfo, completionHandler: completion)

        // Assert
        XCTAssertFalse(result)
    }

    func testReceiveUserIdMismatch() throws {
        // Arrange
        let userInfo = Dictionary<AnyHashable, Any>.appcuesPush

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
        let result = pushMonitor.didReceiveNotification(userInfo: userInfo, completionHandler: completion)

        // Assert
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(result)
    }

    func testReceiveNoSession() throws {
        // Arrange
        let userInfo = Dictionary<AnyHashable, Any>.appcuesPush

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
        let result = pushMonitor.didReceiveNotification(userInfo: userInfo, completionHandler: completion)

        // Assert
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(result)
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
            "appcues_account_id": "103523",
            "appcues_user_id": "default-00000",
            "appcues_notification_id": "DEADBEEF-0000-0000-0000-000000000001",
            "appcues_workflow_id": "DEADBEEF-0000-0000-0000-000000000002",
            "appcues_workflow_task_id": "DEADBEEF-0000-0000-0000-000000000003",
            "appcues_transaction_id": "DEADBEEF-0000-0000-0000-000000000004"
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
