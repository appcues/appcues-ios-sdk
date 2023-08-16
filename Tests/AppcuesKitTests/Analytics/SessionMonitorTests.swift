//
//  SessionMonitorTests.swift
//  AppcuesKitTests
//
//  Created by James Ellis on 4/1/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class SessionMonitorTests: XCTestCase {

    var sessionMonitor: SessionMonitor!
    var appcues: MockAppcues!

    override func setUp() {
        let config = Appcues.Config(accountID: "00000", applicationID: "abc")
        appcues = MockAppcues(config: config)
        sessionMonitor = SessionMonitor(container: appcues.container)
    }

    override func tearDown() {
        // SessionMonitor uses the shared NotificationCenter.default when listening to system
        // foreground/background notifications - we need to unhook these listeners after each test
        // so that no instance lingers around and fulfills expectations more than once due to
        // that shared resource triggering additional events to flow through the system on older
        // Appcues instances from previous tests.
        appcues.analyticsTracker.onFlush = nil
    }

    func testStart() throws {
        // Arrange
        appcues.storage.userID = "user123"

        // Act
        let sessionStarted = sessionMonitor.start()

        // Assert
        XCTAssertTrue(sessionStarted)
        XCTAssertTrue(appcues.isActive)
    }

    func testStartNoUser() throws {
        // Arrange
        appcues.storage.userID = ""

        // Act
        let sessionStarted = sessionMonitor.start()

        // Assert
        XCTAssertFalse(sessionStarted)
        XCTAssertFalse(appcues.isActive)
    }

    func testReset() throws {
        // Arrange
        appcues.storage.userID = "user123"
        let sessionStarted = sessionMonitor.start()
        let onFlushExpectation = expectation(description: "analytics tracker flushed")
        appcues.analyticsTracker.onFlush = {
            onFlushExpectation.fulfill()
        }

        // Act
        sessionMonitor.reset()

        // Assert
        XCTAssertTrue(sessionStarted)
        waitForExpectations(timeout: 1)
        XCTAssertFalse(appcues.isActive)
    }

    func testBackground() throws {
        // Arrange
        appcues.storage.userID = "user123"
        let sessionStarted = sessionMonitor.start()
        let onFlushExpectation = expectation(description: "analytics tracker flushed")
        appcues.analyticsTracker.onFlush = {
            onFlushExpectation.fulfill()
        }

        // Act
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: self, userInfo: nil)

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertTrue(appcues.isActive)
        XCTAssertTrue(sessionStarted)
    }

    func testBackgroundNoSession() throws {
        // Arrange
        let onFlushExpectation = expectation(description: "analytics tracker flushed")
        onFlushExpectation.isInverted = true
        appcues.analyticsTracker.onFlush = {
            onFlushExpectation.fulfill()
        }

        // Act
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: self, userInfo: nil)

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertFalse(appcues.isActive)
    }
}
