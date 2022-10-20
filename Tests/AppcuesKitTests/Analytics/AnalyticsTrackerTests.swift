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
            ["my_key":"my_value", "another_key": 33].verifyPropertiesMatch(activity.profileUpdate)
            onRequestExpectation.fulfill()
        }

        let update = TrackingUpdate(type: .profile(interactive: true), properties: ["my_key":"my_value", "another_key": 33], isInternal: false)

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
            expectedEvents.verifyMatchingEvents(activity.events)
            onRequestExpectation.fulfill()
        }

        let update = TrackingUpdate(type: .event(name: "eventName", interactive: true), properties: ["my_key":"my_value", "another_key": 33], isInternal: false)

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
            expectedEvents.verifyMatchingEvents(activity.events)
            onRequestExpectation.fulfill()
        }

        let update = TrackingUpdate(type: .screen("My test page"), properties: ["my_key":"my_value", "another_key": 33], isInternal: false)

        // Act
        tracker.track(update: update)

        // Assert
        waitForExpectations(timeout: 1)
    }
}

// Helpers to test an Activity request body is as expected
extension Dictionary where Key == String, Value == Any {

    func verifyPropertiesMatch(_ other: [String: Any]?, file: StaticString = #file, line: UInt = #line) {
        guard let other = other else {
            XCTFail("dictionary of actual values must not be nil")
            return
        }
        XCTAssertEqual(Set(self.keys), Set(other.keys), file: file, line: line)
        self.keys.forEach { key in
            switch(self[key], other[key]) {
            case let (val1 as String, val2 as String):
                XCTAssertEqual(val1, val2, file: file, line: line)
            case let (val1 as NSNumber, val2 as NSNumber):
                XCTAssertEqual(val1, val2, file: file, line: line)
            case let (val1 as [Any], val2 as [Any]):
                val1.verifyPropertiesMatch(val2, file: file, line: line)
            case let (val1 as [String: Any], val2 as [String: Any]):
                val1.verifyPropertiesMatch(val2, file: file, line: line)
            case let (val1 as ExperienceData.StepState, val2 as ExperienceData.StepState):
                XCTAssertEqual(val1, val2, file: file, line: line)
            default:
                XCTFail("\(self[key] ?? "nil") does not match \(other[key] ?? "nil").", file: file, line: line)
            }
        }
    }
}

extension Array where Element == Any {

    func verifyPropertiesMatch(_ other: [Any]?, file: StaticString = #file, line: UInt = #line) {
        guard let other = other else {
            XCTFail("dictionary of actual values must not be nil")
            return
        }
        XCTAssertEqual(self.count, other.count, file: file, line: line)

        zip(self, other).forEach { (selfVal, otherVal) in
            switch(selfVal, otherVal) {
            case let (val1 as String, val2 as String):
                XCTAssertEqual(val1, val2, file: file, line: line)
            case let (val1 as NSNumber, val2 as NSNumber):
                XCTAssertEqual(val1, val2, file: file, line: line)
            case let (val1 as [Any], val2 as [Any]):
                val1.verifyPropertiesMatch(val2, file: file, line: line)
            case let (val1 as [String: Any], val2 as [String: Any]):
                val1.verifyPropertiesMatch(val2, file: file, line: line)
            case let (val1 as ExperienceData.StepState, val2 as ExperienceData.StepState):
                XCTAssertEqual(val1, val2, file: file, line: line)
            default:
                XCTFail("\(selfVal) does not match \(otherVal).", file: file, line: line)
            }
        }
    }
}

private extension Array where Element == Event {

    func verifyMatchingEvents(_ other: [Event]?) {
        guard let other = other else {
            XCTFail("array of events must not be nil")
            return
        }
        XCTAssertEqual(self.count, other.count)

        // Compare each event in order
        zip(self, other).forEach { expectEvent, actualEvent in
            XCTAssertEqual(actualEvent.name, expectEvent.name)
            let expectedAttrs = expectEvent.attributes ?? [:]
            let acualAttrs = actualEvent.attributes ?? [:]
            expectedAttrs.verifyPropertiesMatch(acualAttrs)
        }
    }

}

