//
//  AnalyticsTrackerTests.swift
//  AppcuesKitTests
//
//  Created by James Ellis on 11/22/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class AnalyticsTrackerTests: XCTestCase {

    var tracker: AnalyticsTracker!
    var appcues: MockAppcues!

    override func setUpWithError() throws {
        let config = Appcues.Config(accountID: "00000", applicationID: "abc")
            .anonymousIDFactory({ "my-anonymous-id" })

        appcues = MockAppcues(config: config)
        tracker = AnalyticsTracker(container: appcues.container)

        // To test the AnalyticsTracker, we verify that the given tracking update is translated into the expected
        // Activity structure and pushed through to the ActivityProcessor.
    }

    func testIdentifyTracking() throws {
        // Arrange
        let onRequestExpectation = expectation(description: "Valid request")

        // In the case of a profile update, verify the update is sent to the activity processor as
        // an Activity with the expected properties, synchronous (sync=true)
        appcues.activityProcessor.onProcess = { activity, completion in
            // Assert (do/catch necessary because the closure is non-throwing)
            do {
                try ["my_key":"my_value", "another_key": 33].verifyPropertiesMatch(activity.profileUpdate)
                onRequestExpectation.fulfill()
            } catch {
                XCTFail(error.localizedDescription)
            }
        }

        let update = TrackingUpdate(type: .profile, properties: ["my_key":"my_value", "another_key": 33])

        // Act
        tracker.track(update: update)

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testTrackEventRequestBody() throws {
        // Arrange
        let onRequestExpectation = expectation(description: "Valid request")
        let expectedEvents = [Event(name: "eventName", attributes: ["my_key": "my_value", "another_key": 33])]

        // In the case of a tracked event, verify the update is sent to the activity processor as
        // an Activity with the expected event structure, synchronous (sync=true)
        appcues.activityProcessor.onProcess = { activity, completion in
            // Assert (do/catch necessary because the closure is non-throwing)
            do {
                try expectedEvents.verifyMatchingEvents(activity.events)
                onRequestExpectation.fulfill()
            } catch {
                XCTFail(error.localizedDescription)
            }
        }

        let update = TrackingUpdate(type: .event(name: "eventName", interactive: true), properties: ["my_key":"my_value", "another_key": 33])

        // Act
        tracker.track(update: update)

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testTrackScreenRequestBody() throws {
        // Arrange
        let onRequestExpectation = expectation(description: "Valid request")
        let expectedEvents = [Event(screen: "My test page", attributes: ["my_key":"my_value", "another_key": 33])]

        // In the case of a tracked screen, verify the update is sent to the activity processor as
        // an Activity with the expected screen event structure, synchronous (sync=true)
        appcues.activityProcessor.onProcess = { activity, completion in
            // Assert (do/catch necessary because the closure is non-throwing)
            do {
                try expectedEvents.verifyMatchingEvents(activity.events)
                onRequestExpectation.fulfill()
            } catch {
                XCTFail(error.localizedDescription)
            }
        }

        let update = TrackingUpdate(type: .screen("My test page"), properties: ["my_key":"my_value", "another_key": 33])

        // Act
        tracker.track(update: update)

        // Assert
        waitForExpectations(timeout: 1)
    }
}

// Helpers to test an Activity request body is as expected
extension Dictionary where Key == String, Value == Any {

    func verifyPropertiesMatch(_ other: [String: Any]?) throws {
        guard let other = other else {
            XCTFail("dictionary of actual values must not be nil")
            return
        }
        XCTAssertEqual(Set(self.keys), Set(other.keys))
        self.keys.forEach { key in
            switch(self[key], other[key]) {
            case let (val1 as String, val2 as String):
                XCTAssertEqual(val1, val2)
            case let (val1 as Int, val2 as Int):
                XCTAssertEqual(val1, val2)
            case let (val1 as Double, val2 as Double):
                XCTAssertEqual(val1, val2)
            case let (val1 as Bool, val2 as Bool):
                XCTAssertEqual(val1, val2)
            default:
                XCTFail("\(self[key] ?? "nil") does not match \(other[key] ?? "nil").")
            }
        }
    }
}

private extension Array where Element == Event {

    func verifyMatchingEvents(_ other: [Event]?) throws {
        guard let other = other else {
            XCTFail("array of events must not be nil")
            return
        }
        XCTAssertEqual(self.count, other.count)

        // Compare each event in order
        zip(self, other).forEach { expectEvent, actualEvent in
            XCTAssertEqual(actualEvent.name, expectEvent.name)
            do {
                let expectedAttrs = expectEvent.attributes ?? [:]
                let acualAttrs = actualEvent.attributes ?? [:]
                try expectedAttrs.verifyPropertiesMatch(acualAttrs)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }

}

