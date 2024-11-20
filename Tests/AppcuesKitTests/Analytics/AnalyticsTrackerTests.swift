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

    let emptySuccessResponse = QualifyResponse(
        experiences: [],
        performedQualification: true,
        qualificationReason: .screenView,
        experiments: nil
    )

    override func setUpWithError() throws {
        let config = Appcues.Config(accountID: "00000", applicationID: "abc")
            .anonymousIDFactory({ "my-anonymous-id" })

        appcues = MockAppcues(config: config)
        appcues.sessionID = UUID()
        tracker = AnalyticsTracker(container: appcues.container)

        // To test the AnalyticsTracker, we verify that the given tracking update is translated into the expected
        // Activity structure and pushed through to the ActivityProcessor.
    }

    func testIdentifyTracking() async throws {
        // Arrange
        let onRequestExpectation = expectation(description: "Valid request")

        // In the case of a profile update, verify the update is sent to the activity processor as
        // an Activity with the expected properties, synchronous (sync=true)
        appcues.activityProcessor.onProcess = { activity in
            ["my_key":"my_value", "another_key": 33].verifyPropertiesMatch(activity.profileUpdate)
            onRequestExpectation.fulfill()
            return self.emptySuccessResponse
        }

        let update = TrackingUpdate(type: .profile(interactive: true), properties: ["my_key":"my_value", "another_key": 33], isInternal: false)

        // Act
        tracker.track(update: update)

        // Assert
        await fulfillment(of: [onRequestExpectation], timeout: 1)
    }

    func testIdentifyWithSignature() async throws {
        // Arrange
        let onRequestExpectation = expectation(description: "Valid request")

        // In the case of a profile update, verify the update is sent to the activity processor as
        // an Activity with the expected properties, synchronous (sync=true)
        appcues.activityProcessor.onProcess = { activity in
            XCTAssertEqual("user-signature", activity.userSignature)
            onRequestExpectation.fulfill()
            return self.emptySuccessResponse
        }
        appcues.storage.userSignature = "user-signature"
        let update = TrackingUpdate(type: .profile(interactive: true), isInternal: false)

        // Act
        tracker.track(update: update)

        // Assert
        await fulfillment(of: [onRequestExpectation], timeout: 1)
    }

    func testIdentifyWithGroup() async throws {
        // Arrange
        let onRequestExpectation = expectation(description: "Valid request")

        // In the case of a profile update, immediately followed by a group update, verify that the
        // updates get merged together in a single Activity that gets sent to the ActivityProcessor
        appcues.activityProcessor.onProcess = { activity in
            ["userProp":1].verifyPropertiesMatch(activity.profileUpdate)
            ["groupProp":2].verifyPropertiesMatch(activity.groupUpdate)
            XCTAssertEqual("test-group", activity.groupID)
            onRequestExpectation.fulfill()
            return self.emptySuccessResponse
        }

        let profileUpdate = TrackingUpdate(type: .profile(interactive: true), properties: ["userProp":1], isInternal: false)
        let groupUpdate = TrackingUpdate(type: .group("test-group"), properties: ["groupProp":2], isInternal: false)

        // Act
        tracker.track(update: profileUpdate)
        appcues.storage.groupID = "test-group" // mimick what is done in Appcues group() call
        tracker.track(update: groupUpdate)

        // Assert
        await fulfillment(of: [onRequestExpectation], timeout: 1)
    }

    func testIdentifyWithDifferentUser() async throws {
        // Arrange
        let onRequestExpectation = expectation(description: "Valid request")
        onRequestExpectation.expectedFulfillmentCount = 2

        var updateCount = 0

        // In the case of a profile update, immediately followed by another identify with a different
        // user, there should be no batching of the Activity, as the first user profile update must
        // be sent, then the second update with the new user.
        appcues.activityProcessor.onProcess = { activity in
            updateCount += 1
            if updateCount == 1 {
                ["userProp":1].verifyPropertiesMatch(activity.profileUpdate)
                XCTAssertEqual("user-1", activity.userID)
            } else if updateCount == 2 {
                ["userProp":2].verifyPropertiesMatch(activity.profileUpdate)
                XCTAssertEqual("user-2", activity.userID)
            }
            onRequestExpectation.fulfill()
            return self.emptySuccessResponse
        }

        let profileUpdate1 = TrackingUpdate(type: .profile(interactive: true), properties: ["userProp":1], isInternal: false)
        let profileUpdate2 = TrackingUpdate(type: .profile(interactive: true), properties: ["userProp":2], isInternal: false)

        // Act
        appcues.storage.userID = "user-1" // mimick what is done in Appcues identify() call
        tracker.track(update: profileUpdate1)
        appcues.storage.userID = "user-2" // mimick what is done in Appcues identify() call
        tracker.track(update: profileUpdate2)

        // Assert
        await fulfillment(of: [onRequestExpectation], timeout: 1)
    }

    func testIdentifyWithScreen() async throws {
        // Arrange
        let onRequestExpectation = expectation(description: "Valid request")
        let expectedEvents = [Event(name: "appcues:screen_view", attributes: ["screenTitle":"screen-name"])]

        // In the case of a profile update, immediately followed by a screen view, verify that the
        // updates get merged together in a single Activity that gets sent to the ActivityProcessor
        appcues.activityProcessor.onProcess = { activity in
            ["userProp":1].verifyPropertiesMatch(activity.profileUpdate)
            expectedEvents.verifyMatchingEvents(activity.events)
            onRequestExpectation.fulfill()
            return self.emptySuccessResponse
        }

        let profileUpdate = TrackingUpdate(type: .profile(interactive: true), properties: ["userProp":1], isInternal: false)
        let screenUpdate = TrackingUpdate(type: .screen("screen-name"), isInternal: false)

        // Act
        tracker.track(update: profileUpdate)
        tracker.track(update: screenUpdate)

        // Assert
        await fulfillment(of: [onRequestExpectation], timeout: 1)
    }

    func testIdentifyWithDelayThenScreen() async throws {
        // Arrange
        let onRequestExpectation = expectation(description: "Valid request")
        onRequestExpectation.expectedFulfillmentCount = 2
        let expectedEvents = [Event(name: "appcues:screen_view", attributes: ["screenTitle":"screen-name"])]
        var updateCount = 0

        // In the case of a profile update, followed after by a screen update that
        // occurs > than the 50ms batch time on identify, there should be two requests
        // sent with two different Activity payloads
        appcues.activityProcessor.onProcess = { activity in
            updateCount += 1
            if updateCount == 1 {
                ["userProp":1].verifyPropertiesMatch(activity.profileUpdate)
                XCTAssertNil(activity.events)
            } else if updateCount == 2 {
                expectedEvents.verifyMatchingEvents(activity.events)
            }
            onRequestExpectation.fulfill()
            return self.emptySuccessResponse
        }

        let profileUpdate = TrackingUpdate(type: .profile(interactive: true), properties: ["userProp":1], isInternal: false)
        let screenUpdate = TrackingUpdate(type: .screen("screen-name"), isInternal: false)

        // Act
        tracker.track(update: profileUpdate)
        try await Task.sleep(nanoseconds: 1_000_000_000 / 10) // 50 ms batch time is supported for profile update above - wait longer than 50ms (100ms) to avoid batch
        tracker.track(update: screenUpdate)

        // Assert
        await fulfillment(of: [onRequestExpectation], timeout: 1)
    }

    func testGroupTracking() async throws {
        // Arrange
        let onRequestExpectation = expectation(description: "Valid request")

        // In the case of a group update, verify the update is sent to the activity processor as
        // an Activity with the expected properties, synchronous (sync=true)
        appcues.activityProcessor.onProcess = { activity in
            ["my_key":"my_value", "another_key": 33].verifyPropertiesMatch(activity.groupUpdate)
            XCTAssertEqual("test-group", activity.groupID)
            onRequestExpectation.fulfill()
            return self.emptySuccessResponse
        }

        let update = TrackingUpdate(type: .group("test-group"), properties: ["my_key":"my_value", "another_key": 33], isInternal: false)

        // Act
        appcues.storage.groupID = "test-group" // mimick what is done in Appcues group() call
        tracker.track(update: update)

        // Assert
        await fulfillment(of: [onRequestExpectation], timeout: 1)
    }

    func testGroupWithSignature() async throws {
        // Arrange
        let onRequestExpectation = expectation(description: "Valid request")

        // In the case of a group update, verify the update is sent to the activity processor as
        // an Activity with the expected properties, synchronous (sync=true)
        appcues.activityProcessor.onProcess = { activity in
            XCTAssertEqual("user-signature", activity.userSignature)
            onRequestExpectation.fulfill()
            return self.emptySuccessResponse
        }

        appcues.storage.userSignature = "user-signature"
        let update = TrackingUpdate(type: .group("test-group"), isInternal: false)

        // Act
        tracker.track(update: update)

        // Assert
        await fulfillment(of: [onRequestExpectation], timeout: 1)
    }

    func testTrackEventRequestBody() async throws {
        // Arrange
        let onRequestExpectation = expectation(description: "Valid request")
        let expectedEvents = [Event(name: "eventName", attributes: ["my_key": "my_value", "another_key": 33])]

        // In the case of a tracked event, verify the update is sent to the activity processor as
        // an Activity with the expected event structure, synchronous (sync=true)
        appcues.activityProcessor.onProcess = { activity in
            expectedEvents.verifyMatchingEvents(activity.events)
            onRequestExpectation.fulfill()
            return self.emptySuccessResponse
        }

        let update = TrackingUpdate(type: .event(name: "eventName", interactive: true), properties: ["my_key":"my_value", "another_key": 33], isInternal: false)

        // Act
        tracker.track(update: update)

        // Assert
        await fulfillment(of: [onRequestExpectation], timeout: 1)
    }

    func testTrackEventWithSignature() async throws {
        // Arrange
        let onRequestExpectation = expectation(description: "Valid request")

        // In the case of a tracked event, verify the update is sent to the activity processor as
        // an Activity with the expected event structure, synchronous (sync=true)
        appcues.activityProcessor.onProcess = { activity in
            XCTAssertEqual("user-signature", activity.userSignature)
            onRequestExpectation.fulfill()
            return self.emptySuccessResponse
        }

        appcues.storage.userSignature = "user-signature"
        let update = TrackingUpdate(type: .event(name: "eventName", interactive: true), isInternal: false)

        // Act
        tracker.track(update: update)

        // Assert
        await fulfillment(of: [onRequestExpectation], timeout: 1)
    }

    func testTrackScreenRequestBody() async throws {
        // Arrange
        let onRequestExpectation = expectation(description: "Valid request")
        let expectedEvents = [Event(screen: "My test page", attributes: ["my_key":"my_value", "another_key": 33])]

        // In the case of a tracked screen, verify the update is sent to the activity processor as
        // an Activity with the expected screen event structure, synchronous (sync=true)
        appcues.activityProcessor.onProcess = { activity in
            expectedEvents.verifyMatchingEvents(activity.events)
            onRequestExpectation.fulfill()
            return self.emptySuccessResponse
        }

        let update = TrackingUpdate(type: .screen("My test page"), properties: ["my_key":"my_value", "another_key": 33], isInternal: false)

        // Act
        tracker.track(update: update)

        // Assert
        await fulfillment(of: [onRequestExpectation], timeout: 1)
    }

    func testTrackScreenWithSignature() async throws {
        // Arrange
        let onRequestExpectation = expectation(description: "Valid request")

        // In the case of a tracked screen, verify the update is sent to the activity processor as
        // an Activity with the expected screen event structure, synchronous (sync=true)
        appcues.activityProcessor.onProcess = { activity in
            XCTAssertEqual("user-signature", activity.userSignature)
            onRequestExpectation.fulfill()
            return self.emptySuccessResponse
        }

        appcues.storage.userSignature = "user-signature"
        let update = TrackingUpdate(type: .screen("My test page"), isInternal: false)

        // Act
        tracker.track(update: update)

        // Assert
        await fulfillment(of: [onRequestExpectation], timeout: 1)
    }

    func testQueuedEvents() async throws {
        // Arrange
        appcues.config.flushAfterDuration = 2

        let minTimeExpectation = expectation(description: "Valid request")
        let onRequestExpectation = expectation(description: "Waited the flush duration")
        let expectedEvents = [
            Event(name: "appcues:v2:step_interaction", attributes: ["my_key": "my_value", "another_key": 33]),
            Event(name: "appcues:v2:step_interaction", attributes: ["another_key": 100])
        ]

        appcues.activityProcessor.onProcess = { activity in
            expectedEvents.verifyMatchingEvents(activity.events)
            onRequestExpectation.fulfill()
            return self.emptySuccessResponse
        }

        let update1 = TrackingUpdate(type: .event(name: "appcues:v2:step_interaction", interactive: false), properties: ["my_key":"my_value", "another_key": 33], isInternal: false)
        let update2 = TrackingUpdate(type: .event(name: "appcues:v2:step_interaction", interactive: false), properties: ["another_key": 100], isInternal: false)

        DispatchQueue.main.asyncAfter(deadline: .now() + appcues.config.flushAfterDuration) {
            // Fulfill this expectation after the flush duration. This, combined with `enforceOrder` below, verifies
            // that the AnalyticsTracker is waiting and not triggering the event right away.
            minTimeExpectation.fulfill()
        }

        // Act
        tracker.track(update: update1)
        tracker.track(update: update2)

        // Assert
        await fulfillment(of: [minTimeExpectation, onRequestExpectation], timeout: appcues.config.flushAfterDuration + 1, enforceOrder: true)
    }

    func testProcessEmptyResponse() async throws {
        let onRenderExpectation = expectation(description: "Experience renderer successfully called")
        let successResponse = QualifyResponse(
            experiences: [],
            performedQualification: true,
            qualificationReason: .screenView,
            experiments: nil
        )

        appcues.activityProcessor.onProcess = { activity in
            successResponse
        }

        appcues.experienceRenderer.onProcessAndShow = { data, trigger in
            XCTAssertEqual(data.count, 0)
            XCTAssertEqual(trigger, .qualification(reason: .screenView))
            onRenderExpectation.fulfill()
        }

        let update = TrackingUpdate(type: .screen("My test page"), isInternal: false)

        // Act
        tracker.track(update: update)

        await fulfillment(of: [onRenderExpectation], timeout: 1)
    }

    func testProcessExperienceResponse() async throws {
        let onRenderExpectation = expectation(description: "Experience renderer successfully called")
        let successResponse = QualifyResponse(
            experiences: [.decoded(Experience.mock)],
            performedQualification: true,
            qualificationReason: .screenView,
            experiments: nil
        )

        appcues.activityProcessor.onProcess = { activity in
            successResponse
        }

        appcues.experienceRenderer.onProcessAndShow = { data, trigger in
            XCTAssertEqual(data.count, 1)
            XCTAssertEqual(trigger, .qualification(reason: .screenView))
            onRenderExpectation.fulfill()
        }

        let update = TrackingUpdate(type: .screen("My test page"), isInternal: false)

        // Act
        tracker.track(update: update)

        await fulfillment(of: [onRenderExpectation], timeout: 1)
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
            case let (val1 as ExperienceData.StepState, val2 as ExperienceData.StepState):
                XCTAssertEqual(val1, val2, file: file, line: line)
            case let (val1 as String, val2 as String):
                XCTAssertEqual(val1, val2, file: file, line: line)
            case let (val1 as NSNumber, val2 as NSNumber):
                XCTAssertEqual(val1, val2, file: file, line: line)
            case let (val1 as [Any], val2 as [Any]):
                val1.verifyPropertiesMatch(val2, file: file, line: line)
            case let (val1 as [String: Any], val2 as [String: Any]):
                val1.verifyPropertiesMatch(val2, file: file, line: line)
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
            case let (val1 as ExperienceData.StepState, val2 as ExperienceData.StepState):
                XCTAssertEqual(val1, val2, file: file, line: line)
            case let (val1 as String, val2 as String):
                XCTAssertEqual(val1, val2, file: file, line: line)
            case let (val1 as NSNumber, val2 as NSNumber):
                XCTAssertEqual(val1, val2, file: file, line: line)
            case let (val1 as [Any], val2 as [Any]):
                val1.verifyPropertiesMatch(val2, file: file, line: line)
            case let (val1 as [String: Any], val2 as [String: Any]):
                val1.verifyPropertiesMatch(val2, file: file, line: line)
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

