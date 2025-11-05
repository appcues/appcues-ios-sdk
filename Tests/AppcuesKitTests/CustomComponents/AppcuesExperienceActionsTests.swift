//
//  AppcuesExperienceActionsTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2025-11-05.
//  Copyright © 2025 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

@available(iOS 13.0, *)
class AppcuesExperienceActionsTests: XCTestCase {

    var appcues: MockAppcues!
    var actions: AppcuesExperienceActions!

    override func setUpWithError() throws {
        appcues = MockAppcues()
        actions = AppcuesExperienceActions(
            appcues: appcues,
            renderContext: .modal,
            identifier: "test-component"
        )
    }

    func testTriggerBlockActions() throws {
        // Arrange
        let actionModel = Experience.Action(
            trigger: "tap",
            type: "@appcues/track",
            config: AppcuesTrackAction.Config(eventName: "Test Event", attributes: nil)
        )
        actions.actions = [actionModel]

        let expectation = expectation(description: "Action executed")
        appcues.analyticsPublisher.onPublish = { trackingUpdate in
            if case .event(let name, _) = trackingUpdate.type, name == "Test Event" {
                expectation.fulfill()
            }
        }

        // Act
        actions.triggerBlockActions()

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testTrack() throws {
        // Arrange
        let expectation = expectation(description: "Event tracked")
        appcues.analyticsPublisher.onPublish = { trackingUpdate in
            if case .event(let name, _) = trackingUpdate.type {
                XCTAssertEqual(name, "Custom Event")
                XCTAssertEqual(trackingUpdate.properties?["key"] as? String, "value")
                expectation.fulfill()
            }
        }

        // Act
        actions.track(name: "Custom Event", properties: ["key": "value"])

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testNextStep() throws {
        // Arrange
        let expectation = expectation(description: "Navigated to next step")
        appcues.experienceRenderer.onShowStep = { stepRef, _, completion in
            if case .offset(let offset) = stepRef {
                XCTAssertEqual(offset, 1)
            } else {
                XCTFail("Expected offset(1) step reference")
            }
            completion?()
            expectation.fulfill()
        }

        // Act
        actions.nextStep()

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testPreviousStep() throws {
        // Arrange
        let expectation = expectation(description: "Navigated to previous step")
        appcues.experienceRenderer.onShowStep = { stepRef, _, completion in
            if case .offset(let offset) = stepRef {
                XCTAssertEqual(offset, -1)
            } else {
                XCTFail("Expected offset(-1) step reference")
            }
            completion?()
            expectation.fulfill()
        }

        // Act
        actions.previousStep()

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testClose() throws {
        // Arrange
        let expectation = expectation(description: "Experience dismissed")
        appcues.experienceRenderer.onDismiss = { _, markComplete, completion in
            XCTAssertEqual(markComplete, true)
            expectation.fulfill()
            completion?(.success(()))
        }

        // Act
        actions.close(markComplete: true)

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testUpdateProfile() throws {
        // Arrange
        let expectation = expectation(description: "Profile updated")
        appcues.onIdentify = { _, properties in
            XCTAssertEqual(properties?["name"] as? String, "John")
            XCTAssertEqual(properties?["age"] as? Int, 30)
            expectation.fulfill()
        }

        // Act
        actions.updateProfile(properties: ["name": "John", "age": 30])

        // Assert
        waitForExpectations(timeout: 1)
    }
}
