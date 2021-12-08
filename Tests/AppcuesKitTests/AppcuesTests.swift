//
//  AppcuesTests.swift
//  AppcuesTests
//
//  Created by Matt on 2021-10-06.
//  Copyright © 2021 Appcues. All rights reserved.
//

import XCTest
import Mocker
@testable import AppcuesKit

class AppcuesTests: XCTestCase {
    var appcues: Appcues!

    override func setUpWithError() throws {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        let urlSession = URLSession(configuration: configuration)

        let config = Appcues.Config(accountID: "00001", applicationID: "abc")
            .urlSession(urlSession)
            .anonymousIDFactory({ "my-anonymous-id" })

        appcues = Appcues(config: config)
    }

    override func tearDownWithError() throws {
        UserDefaults.standard.removePersistentDomain(forName: "com.appcues.storage.00000")
    }

    func testAnonymousTracking() throws {
        // Test to validate that (1) no activity flows through system when no user has been identified (anon or auth)
        // and (2) validate that activity does begin flowing through once the user is known (anon or auth)

        // Arrange
        let subscriber = TestSubscriber()
        appcues.reset() //start out with Appcues disabled - no user
        appcues.register(subscriber: subscriber) //use a test subscriber to listen to updates coming through the system

        // Act
        appcues.screen(title: "My test page", properties: ["my_key":"my_value", "another_key": 33])            //not tracked
        appcues.anonymous()                                                                                    //tracked - user (+1 session start)
        appcues.screen(title: "My test page", properties: ["my_key":"my_value", "another_key": 33])            //tracked - screen
        appcues.reset()                                                                                        //reset (+1 session end)
        appcues.screen(title: "My test page", properties: ["my_key":"my_value", "another_key": 33])            //not tracked
        appcues.identify(userID: "specific-user-id", properties: ["my_key":"my_value", "another_key": 33])     //tracked - user (+1 session start)
        appcues.screen(title: "My test page", properties: ["my_key":"my_value", "another_key": 33])            //tracked - screen

        // Assert
        XCTAssertEqual(subscriber.trackedUpdates, 7)
    }
}

private class TestSubscriber: AnalyticsSubscriber {
    var trackedUpdates = 0

    func track(update: TrackingUpdate) {
        trackedUpdates += 1
    }
}
