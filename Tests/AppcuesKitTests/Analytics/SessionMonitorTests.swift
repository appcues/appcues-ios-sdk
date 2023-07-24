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
        appcues.analyticsPublisher.onPublish = nil
        appcues.analyticsTracker.onFlush = nil
    }

    func testStart() throws {
        // Arrange
        let onTrackExpectation = expectation(description: "session analytics tracked")
        appcues.storage.userID = "user123"
        appcues.analyticsPublisher.onPublish = { trackingUpdate in
            if case .event(SessionEvents.sessionStarted.rawValue, let interactive) = trackingUpdate.type {
                XCTAssertTrue(interactive)
                XCTAssertNil(trackingUpdate.properties)
                onTrackExpectation.fulfill()
            }
        }

        // Act
        sessionMonitor.start()

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertTrue(appcues.isActive)
    }

    func testStartNoUser() throws {
        // Arrange
        let onTrackExpectation = expectation(description: "session analytics tracked")
        onTrackExpectation.isInverted = true
        appcues.storage.userID = ""
        appcues.analyticsPublisher.onPublish = { trackingUpdate in
            if case .event(SessionEvents.sessionStarted.rawValue, _) = trackingUpdate.type {
                onTrackExpectation.fulfill()
            }
        }

        // Act
        sessionMonitor.start()

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertFalse(appcues.isActive)
    }

    func testReset() throws {
        // Arrange
        appcues.storage.userID = "user123"
        sessionMonitor.start()
        appcues.storage.userID = ""
        let onTrackExpectation = expectation(description: "session analytics tracked")
        appcues.analyticsPublisher.onPublish = { trackingUpdate in
            if case .event(SessionEvents.sessionReset.rawValue, let interactive) = trackingUpdate.type {
                XCTAssertTrue(interactive)
                XCTAssertNil(trackingUpdate.properties)
                onTrackExpectation.fulfill()
            }
        }

        // Act
        sessionMonitor.reset()

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertFalse(appcues.isActive)
    }

    func testBackground() throws {
        // Arrange
        appcues.storage.userID = "user123"
        sessionMonitor.start()
        let onTrackExpectation = expectation(description: "session analytics tracked")
        let onFlushExpectation = expectation(description: "analytics tracker flushed")
        appcues.analyticsPublisher.onPublish = { trackingUpdate in
            if case .event(SessionEvents.sessionSuspended.rawValue, let interactive) = trackingUpdate.type {
                XCTAssertFalse(interactive)
                XCTAssertNil(trackingUpdate.properties)
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
        XCTAssertTrue(appcues.isActive)
    }

    func testBackgroundNoSession() throws {
        // Arrange
        let onTrackExpectation = expectation(description: "session analytics tracked")
        let onFlushExpectation = expectation(description: "analytics tracker flushed")
        onTrackExpectation.isInverted = true
        onFlushExpectation.isInverted = true
        appcues.analyticsPublisher.onPublish = { trackingUpdate in
            if case .event(SessionEvents.sessionSuspended.rawValue, _) = trackingUpdate.type {
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
        XCTAssertFalse(appcues.isActive)
    }

    func testForegroundNoSession() throws {
        // Arrange
        appcues.storage.userID = "user123"
        sessionMonitor.start()
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: self, userInfo: nil)
        sessionMonitor.reset()
        let onTrackExpectation = expectation(description: "session analytics tracked")
        onTrackExpectation.isInverted = true
        appcues.analyticsPublisher.onPublish = { trackingUpdate in
            if case let .event(name, _) = trackingUpdate.type, name == SessionEvents.sessionStarted.rawValue || name == SessionEvents.sessionResumed.rawValue {
                onTrackExpectation.fulfill()
            }
        }

        // Act
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: self, userInfo: nil)

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertFalse(appcues.isActive)
    }

    func testForegroundNoBackground() throws {
        // Arrange
        appcues.storage.userID = "user123"
        sessionMonitor.start()
        let onTrackExpectation = expectation(description: "session analytics tracked")
        onTrackExpectation.isInverted = true
        appcues.analyticsPublisher.onPublish = { trackingUpdate in
            if case let .event(name, _) = trackingUpdate.type, name == SessionEvents.sessionStarted.rawValue || name == SessionEvents.sessionResumed.rawValue {
                onTrackExpectation.fulfill()
            }
        }

        // Act
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: self, userInfo: nil)

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertTrue(appcues.isActive)
    }

    func testForegroundResume() throws {
        // Arrange
        appcues = MockAppcues(config: Appcues.Config(accountID: "00000", applicationID: "abc").sessionTimeout(1_800))
        sessionMonitor = SessionMonitor(container: appcues.container)
        appcues.storage.userID = "user123"
        sessionMonitor.start()
        let initialSessionId = appcues.sessionID
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: self, userInfo: nil)
        let onTrackExpectation = expectation(description: "session analytics tracked")
        appcues.analyticsPublisher.onPublish = { trackingUpdate in
            if case .event(SessionEvents.sessionResumed.rawValue, _) = trackingUpdate.type {
                let updatedSessionId = self.appcues.sessionID
                XCTAssertNotNil(initialSessionId)
                XCTAssertEqual(initialSessionId, updatedSessionId)
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
        let initialSessionId = appcues.sessionID
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: self, userInfo: nil)
        let onTrackExpectation = expectation(description: "session analytics tracked")
        appcues.analyticsPublisher.onPublish = { trackingUpdate in
            if case .event(SessionEvents.sessionStarted.rawValue, _) = trackingUpdate.type {
                let updatedSessionId = self.appcues.sessionID
                XCTAssertNotNil(initialSessionId)
                XCTAssertNotNil(updatedSessionId)
                XCTAssertNotEqual(initialSessionId, updatedSessionId)
                onTrackExpectation.fulfill()
            }
        }

        // Act
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: self, userInfo: nil)

        // Assert
        waitForExpectations(timeout: 1)
    }
}
