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
        appcues.sessionMonitor.isActive = false //start out with Appcues disabled - no user
        appcues.register(subscriber: subscriber) //use a test subscriber to listen to updates coming through the system

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
        XCTAssertEqual(subscriber.trackedUpdates, 4)
    }
}

private class TestSubscriber: AnalyticsSubscribing {
    var trackedUpdates = 0

    func track(update: TrackingUpdate) {
        trackedUpdates += 1
    }
}
