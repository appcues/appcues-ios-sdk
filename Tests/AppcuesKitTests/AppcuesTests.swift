//
//  AppcuesTests.swift
//  AppcuesTests
//
//  Created by Matt on 2021-10-06.
//  Copyright © 2021 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class AppcuesTests: XCTestCase {
    var appcues: MockAppcues!

    override func setUpWithError() throws {
        let config = Appcues.Config(accountID: "00001", applicationID: "abc")
            .anonymousIDFactory({ "my-anonymous-id" })

        appcues = MockAppcues(config: config)
    }

    func testAnonymousTracking() throws {
        // Test to validate that (1) no activity flows through system when no user has been identified (anon or auth)
        // and (2) validate that activity does begin flowing through once the user is known (anon or auth)

        // Arrange
        let subscriber = TestSubscriber()
        appcues.register(subscriber: subscriber)
        appcues.sessionMonitor.isActive = false //start out with Appcues disabled - no user

        appcues.sessionMonitor.onStart = {
            self.appcues.sessionMonitor.isActive = true
        }

        appcues.sessionMonitor.onReset = {
            self.appcues.sessionMonitor.isActive = false
        }

        // Act
        appcues.screen(title: "My test page", properties: ["my_key":"my_value", "another_key": 33])            //not tracked
        appcues.anonymous()                                                                                    //tracked - user
        appcues.screen(title: "My test page", properties: ["my_key":"my_value", "another_key": 33])            //tracked - screen
        appcues.reset()                                                                                        //stop tracking
        appcues.screen(title: "My test page", properties: ["my_key":"my_value", "another_key": 33])            //not tracked
        appcues.identify(userID: "specific-user-id", properties: ["my_key":"my_value", "another_key": 33])     //tracked - user
        appcues.screen(title: "My test page", properties: ["my_key":"my_value", "another_key": 33])            //tracked - screen

        // Assert
        XCTAssertEqual(4, subscriber.trackedUpdates)
    }

    func testIdentifyWithEmptyUserIsNotTracked() throws {
        // Arrange
        let subscriber = TestSubscriber()
        appcues.register(subscriber: subscriber)

        // Act
        appcues.identify(userID: "", properties: nil)

        // Assert
        XCTAssertEqual(0, subscriber.trackedUpdates)
    }

    func testSetGroup() throws {
        // Arrange
        let subscriber = TestSubscriber()
        appcues.register(subscriber: subscriber)

        // Act
        appcues.group(groupID: "group1", properties: ["my_key":"my_value", "another_key": 33])

        // Assert
        let lastUpdate = try XCTUnwrap(subscriber.lastUpdate)
        guard case .group = lastUpdate.type else { return XCTFail() }
        try ["my_key":"my_value", "another_key": 33].verifyPropertiesMatch(lastUpdate.properties)
        XCTAssertEqual("group1", appcues.storage.groupID)
    }

    func testNilGroupIDRemovesGroup() throws {
        // Arrange
        let subscriber = TestSubscriber()
        appcues.register(subscriber: subscriber)

        // Act
        appcues.group(groupID: nil, properties: ["my_key":"my_value", "another_key": 33])

        // Assert
        let lastUpdate = try XCTUnwrap(subscriber.lastUpdate)
        guard case .group = lastUpdate.type else { return XCTFail() }
        XCTAssertNil(appcues.storage.groupID)
        XCTAssertNil(lastUpdate.properties)
    }

    func testEmptyStringGroupIDRemovesGroup() throws {
        // Arrange
        let subscriber = TestSubscriber()
        appcues.register(subscriber: subscriber)

        // Act
        appcues.group(groupID: "", properties: ["my_key":"my_value", "another_key": 33])

        // Assert
        let lastUpdate = try XCTUnwrap(subscriber.lastUpdate)
        guard case .group = lastUpdate.type else { return XCTFail() }
        XCTAssertNil(appcues.storage.groupID)
        XCTAssertNil(lastUpdate.properties)
    }

    func testRegisterDecorator() throws {
        // Arrange
        let decorator = TestDecorator()

        // Act
        appcues.register(decorator: decorator)
        appcues.track(name: "custom event", properties: nil)

        // Assert
        XCTAssertEqual(1, decorator.decorations)
    }

    func testRemoveDecorator() throws {
        // Arrange
        let decorator = TestDecorator()
        appcues.register(decorator: decorator)
        appcues.track(name: "custom event", properties: nil)

        // Act
        appcues.remove(decorator: decorator)
        appcues.track(name: "custom event", properties: nil)

        // Assert
        XCTAssertEqual(1, decorator.decorations)
    }

    func testClearDecorators() throws {
        // Arrange
        let decorator1 = TestDecorator()
        appcues.register(decorator: decorator1)
        let decorator2 = TestDecorator()
        appcues.register(decorator: decorator2)
        appcues.track(name: "custom event", properties: nil)

        // Act
        appcues.clearDecorators()
        appcues.track(name: "custom event", properties: nil)

        // Assert
        XCTAssertEqual(1, decorator1.decorations)
        XCTAssertEqual(1, decorator2.decorations)
    }

    func testRegisterSubscriber() throws {
        // Arrange
        let subscriber = TestSubscriber()

        // Act
        appcues.register(subscriber: subscriber)
        appcues.track(name: "custom event", properties: nil)

        // Assert
        XCTAssertEqual(1, subscriber.trackedUpdates)
    }

    func testRemoveSubscriber() throws {
        // Arrange
        let subscriber = TestSubscriber()
        appcues.register(subscriber: subscriber)
        appcues.track(name: "custom event", properties: nil)

        // Act
        appcues.remove(subscriber: subscriber)
        appcues.track(name: "custom event", properties: nil)

        // Assert
        XCTAssertEqual(1, subscriber.trackedUpdates)
    }

    func testClearSubscribers() throws {
        // Arrange
        let subscriber1 = TestSubscriber()
        appcues.register(subscriber: subscriber1)
        let subscriber2 = TestSubscriber()
        appcues.register(subscriber: subscriber2)
        appcues.track(name: "custom event", properties: nil)

        // Act
        appcues.clearSubscribers()
        appcues.track(name: "custom event", properties: nil)

        // Assert
        XCTAssertEqual(1, subscriber1.trackedUpdates)
        XCTAssertEqual(1, subscriber2.trackedUpdates)
    }

    func testSdkVersion() throws {
        // Act
        let version = appcues.version()
        let tokens = version.split(separator: ".")

        // Assert
        // just looking for some valid return string with at least a major/minor version
        XCTAssertTrue(tokens.count > 2)
        XCTAssertNotNil(Int(tokens[0]))
        XCTAssertNotNil(Int(tokens[1]))
    }

    func testDebug() throws {
        // Arrange
        let debuggerShownExpectation = expectation(description: "Debugger shown")
        appcues.debugger.onShow = {
            debuggerShownExpectation.fulfill()
        }

        // Act
        appcues.debug()

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testShowExperienceByID() throws {
        // Arrange
        var experienceShown = false
        appcues.experienceLoader.onLoad = { experienceID, published in
            XCTAssertEqual(true, published)
            XCTAssertEqual("1234", experienceID)
            experienceShown = true
        }

        // Act
        appcues.show(experienceID: "1234")

        // Assert
        XCTAssertTrue(experienceShown)
    }

    func testExperienceNotShownIfNoSession() throws {
        // Arrange
        appcues.sessionMonitor.isActive = false
        var experienceShown = false
        appcues.experienceLoader.onLoad = { experienceID, published in
            experienceShown = true
        }

        // Act
        appcues.show(experienceID: "1234")

        // Assert
        XCTAssertFalse(experienceShown)
    }

    func testAutomaticScreenTracking() throws {
        // Arrange
        let screenExpectation = expectation(description: "Screen tracked")
        appcues.onScreen = { title, properties in
            XCTAssertEqual("test screen", title)
            XCTAssertNil(properties)
            screenExpectation.fulfill()
        }

        // Act
        appcues.trackScreens()
        // simulates an automatic tracked screen to verify if tracking is handling
        NotificationCenter.appcues.post(name: .appcuesTrackedScreen,
                                        object: self,
                                        userInfo: Notification.toInfo("test screen"))

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testDidHandleURL() throws {
        // Arrange
        appcues.deeplinkHandler.onDidHandleURL = { url -> Bool in
            XCTAssertEqual(URL(string: "https://www.appcues.com")!, url)
            return true
        }

        // Act
        let result = appcues.didHandleURL(URL(string: "https://www.appcues.com")!)

        // Assert
        XCTAssertTrue(result)
    }
}

private class TestSubscriber: AnalyticsSubscribing {
    var trackedUpdates = 0
    var lastUpdate: TrackingUpdate?

    func track(update: TrackingUpdate) {
        trackedUpdates += 1
        lastUpdate = update
    }
}

private class TestDecorator: AnalyticsDecorating {
    var decorations = 0

    func decorate(_ tracking: TrackingUpdate) -> TrackingUpdate {
        decorations += 1
        return tracking
    }
}
