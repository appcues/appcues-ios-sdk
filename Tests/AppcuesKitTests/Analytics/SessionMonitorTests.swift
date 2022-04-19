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
        // foreground/background notifications - we need to unhook these listners after each test
        // so that no instance lingers around and fulfills expectations more than once due to
        // that shared resource triggering additional events to flow through the system on older
        // Appcues instances from previous tests.
        appcues.onTrack = nil
        appcues.analyticsTracker.onFlush = nil
    }

    func testStart() throws {
        // Arrange
        let onTrackExpectation = expectation(description: "session analytics tracked")
        appcues.storage.userID = "user123"
        appcues.onTrack = { name, props, interactive in
            if name == SessionEvents.sessionStarted.rawValue{
                XCTAssertTrue(interactive)
                XCTAssertNil(props)
                onTrackExpectation.fulfill()
            }
        }

        // Act
        sessionMonitor.start()

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertTrue(sessionMonitor.isActive)
    }

    func testStartNoUser() throws {
        // Arrange
        let onTrackExpectation = expectation(description: "session analytics tracked")
        onTrackExpectation.isInverted = true
        appcues.storage.userID = ""
        appcues.onTrack = { name, _, _ in
            if name == SessionEvents.sessionStarted.rawValue {
                onTrackExpectation.fulfill()
            }
        }

        // Act
        sessionMonitor.start()

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertFalse(sessionMonitor.isActive)
    }

    func testReset() throws {
        // Arrange
        appcues.storage.userID = "user123"
        sessionMonitor.start()
        appcues.storage.userID = ""
        let onTrackExpectation = expectation(description: "session analytics tracked")
        appcues.onTrack = { name, props, interactive in
            if name == SessionEvents.sessionReset.rawValue {
                XCTAssertTrue(interactive)
                XCTAssertNil(props)
                onTrackExpectation.fulfill()
            }
        }

        // Act
        sessionMonitor.reset()

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertFalse(sessionMonitor.isActive)
    }

    func testBackground() throws {
        // Arrange
        appcues.storage.userID = "user123"
        sessionMonitor.start()
        let onTrackExpectation = expectation(description: "session analytics tracked")
        let onFlushExpectation = expectation(description: "analytics tracker flushed")
        appcues.onTrack = { name, props, interactive in
            if name == SessionEvents.sessionSuspended.rawValue {
                XCTAssertFalse(interactive)
                XCTAssertNil(props)
                onTrackExpectation.fulfill()
            }
        }
        appcues.analyticsTracker.onFlush = {
            onFlushExpectation.fulfill()
        }

        // Act
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: self, userInfo: nil)

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertTrue(sessionMonitor.isActive)
    }

    func testBackgroundNoSession() throws {
        // Arrange
        let onTrackExpectation = expectation(description: "session analytics tracked")
        let onFlushExpectation = expectation(description: "analytics tracker flushed")
        onTrackExpectation.isInverted = true
        onFlushExpectation.isInverted = true
        appcues.onTrack = { name, _, _ in
            if name == SessionEvents.sessionSuspended.rawValue {
                onTrackExpectation.fulfill()
            }
        }
        appcues.analyticsTracker.onFlush = {
            onFlushExpectation.fulfill()
        }

        // Act
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: self, userInfo: nil)

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertFalse(sessionMonitor.isActive)
    }

    func testForegroundNoSession() throws {
        // Arrange
        appcues.storage.userID = "user123"
        sessionMonitor.start()
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: self, userInfo: nil)
        sessionMonitor.reset()
        let onTrackExpectation = expectation(description: "session analytics tracked")
        onTrackExpectation.isInverted = true
        appcues.onTrack = { name, _, _ in
            if name == SessionEvents.sessionStarted.rawValue || name == SessionEvents.sessionResumed.rawValue {
                onTrackExpectation.fulfill()
            }
        }

        // Act
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: self, userInfo: nil)

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertFalse(sessionMonitor.isActive)
    }

    func testForegroundNoBackground() throws {
        // Arrange
        appcues.storage.userID = "user123"
        sessionMonitor.start()
        let onTrackExpectation = expectation(description: "session analytics tracked")
        onTrackExpectation.isInverted = true
        appcues.onTrack = { name, _, _ in
            if name == SessionEvents.sessionStarted.rawValue || name == SessionEvents.sessionResumed.rawValue {
                onTrackExpectation.fulfill()
            }
        }

        // Act
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: self, userInfo: nil)

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertTrue(sessionMonitor.isActive)
    }

    func testForegroundResume() throws {
        // Arrange
        appcues = MockAppcues(config: Appcues.Config(accountID: "00000", applicationID: "abc").sessionTimeout(1_800))
        sessionMonitor = SessionMonitor(container: appcues.container)
        appcues.storage.userID = "user123"
        sessionMonitor.start()
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: self, userInfo: nil)
        let onTrackExpectation = expectation(description: "session analytics tracked")
        appcues.onTrack = { name, _, _ in
            if name == SessionEvents.sessionResumed.rawValue {
                onTrackExpectation.fulfill()
            }
        }

        // Act
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: self, userInfo: nil)

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testForegroundStartNewSession() throws {
        // Arrange
        appcues = MockAppcues(config: Appcues.Config(accountID: "00000", applicationID: "abc").sessionTimeout(0))
        sessionMonitor = SessionMonitor(container: appcues.container)
        appcues.storage.userID = "user123"
        sessionMonitor.start()
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: self, userInfo: nil)
        let onTrackExpectation = expectation(description: "session analytics tracked")
        appcues.onTrack = { name, _, _ in
            if name == SessionEvents.sessionStarted.rawValue {
                onTrackExpectation.fulfill()
            }
        }

        // Act
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: self, userInfo: nil)

        // Assert
        waitForExpectations(timeout: 1)
    }
}
