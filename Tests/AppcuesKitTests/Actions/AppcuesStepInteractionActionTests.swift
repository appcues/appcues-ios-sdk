//
//  AppcuesStepInteractionActionTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-10-06.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class AppcuesStepInteractionActionTests: XCTestCase {

    var appcues: MockAppcues!
    var actionRegistry: ActionRegistry!

    override func setUpWithError() throws {
        appcues = MockAppcues()
        actionRegistry = ActionRegistry(container: appcues.container)
    }

    func testInit() throws {
        // Act
        let failedAction = AppcuesStepInteractionAction(configuration: AppcuesExperiencePluginConfiguration(nil, appcues: appcues))

        // Assert
        XCTAssertNil(failedAction)
    }

    func testExecuteUnpublishedExperience() async throws {
        // Arrange
        var loggedUpdates: [TrackingUpdate] = []

        appcues.experienceRenderer.onExperienceData = { _ in
            ExperienceData.mockWithForm(defaultValue: nil, published: false)
        }
        appcues.experienceRenderer.onStepIndex = { _ in
            .initial
        }

        appcues.analyticsPublisher.onPublish = { trackingUpdate in
            XCTFail("unexpected analytics event")
        }
        appcues.analyticsPublisher.onLog = { trackingUpdate in
            loggedUpdates.append(trackingUpdate)
        }


        let action = AppcuesStepInteractionAction(
            appcues: appcues,
            renderContext: .modal,
            interactionType: "Button Tapped",
            viewDescription: "My Button",
            category: "link",
            destination: "https://appcues.com"
        )

        // Act
        try await action.execute()

        // Assert
        XCTAssertEqual(loggedUpdates.count, 1)
        XCTAssertEqual(loggedUpdates[0].type, .event(name: "appcues:v2:step_interaction", interactive: false))
    }

    func testNextStep() async throws {
        // Arrange
        let updateExpectation = expectation(description: "Update set")
        updateExpectation.expectedFulfillmentCount = 2
        var updates: [TrackingUpdate] = []
        let experience = ExperienceData.mock

        appcues.experienceRenderer.onExperienceData = { _ in
            experience
        }
        appcues.experienceRenderer.onStepIndex = { _ in
            .initial
        }

        appcues.analyticsPublisher.onPublish = { update in
            updates.append(update)
            updateExpectation.fulfill()
        }

        // Act
        actionRegistry.enqueue(
            actionModels: [
                Experience.Action(
                    trigger: "tap",
                    type: "@appcues/continue",
                    config: AppcuesContinueAction.Config(index: nil, offset: 1, stepID: nil)),
                Experience.Action(
                    trigger: "tap",
                    type: "@appcues/track",
                    config: AppcuesTrackAction.Config(eventName: "Some event", attributes: nil))
            ],
            level: .step,
            renderContext: .modal,
            interactionType: "Button Tapped",
            viewDescription: "My Button")

        // Assert
        await fulfillment(of: [updateExpectation], timeout: 1)
        XCTAssertEqual(updates.count, 2)
        let firstUpdate = try XCTUnwrap(updates.first)
        XCTAssertEqual(firstUpdate.type, .event(name: "appcues:v2:step_interaction", interactive: false))
        [
            "interactionType": "Button Tapped",
            "interactionData": [
                "category": "internal",
                "destination": "+1",
                "text": "My Button"
            ],
            // Event properties
            "experienceId": experience.id.appcuesFormatted,
            "experienceName": experience.name,
            "experienceType": experience.type,
            "experienceInstanceId": experience.instanceID.appcuesFormatted,
            "trigger": "show_call",
            "localeName": try XCTUnwrap(experience.context?.localeName),
            "localeId": try XCTUnwrap(experience.context?.localeId),
            "stepId": experience.steps[0].items[0].id.appcuesFormatted,
            "stepType": experience.steps[0].items[0].type,
            "stepIndex": "0,0",
            "version": try XCTUnwrap(experience.publishedAt)
        ].verifyPropertiesMatch(firstUpdate.properties)
    }

    func testPreviousStep() async throws {
        // Arrange
        let updateExpectation = expectation(description: "Update set")
        updateExpectation.expectedFulfillmentCount = 2
        var updates: [TrackingUpdate] = []
        appcues.analyticsPublisher.onPublish = { update in
            updates.append(update)
            updateExpectation.fulfill()
        }

        // Act
        actionRegistry.enqueue(
            actionModels: [
                Experience.Action(
                    trigger: "tap",
                    type: "@appcues/continue",
                    config: AppcuesContinueAction.Config(index: nil, offset: -1, stepID: nil)),
                Experience.Action(
                    trigger: "tap",
                    type: "@appcues/track",
                    config: AppcuesTrackAction.Config(eventName: "Some event", attributes: nil))
            ],
            level: .step,
            renderContext: .modal,
            interactionType: "Button Tapped",
            viewDescription: "My Button")

        // Assert
        await fulfillment(of: [updateExpectation], timeout: 1)
        XCTAssertEqual(updates.count, 2)
        let firstUpdate = try XCTUnwrap(updates.first)
        guard case .event(name: "appcues:v2:step_interaction", interactive: false) = firstUpdate.type else { return XCTFail() }
        [
            "interactionType": "Button Tapped",
            "interactionData": [
                "category": "internal",
                "destination": "-1",
                "text": "My Button"
            ]
        ].verifyPropertiesMatch(firstUpdate.properties)
    }

    func testGoToLink() async throws {
        // Arrange
        let updateExpectation = expectation(description: "Update set")
        var mostRecentUpdate: TrackingUpdate?
        appcues.analyticsPublisher.onPublish = { update in
            mostRecentUpdate = update
            updateExpectation.fulfill()
        }

        // Act
        actionRegistry.enqueue(
            actionModels: [
                Experience.Action(
                    trigger: "tap",
                    type: "@appcues/close",
                    config: AppcuesCloseAction.Config(markComplete: true)),
                Experience.Action(
                    trigger: "tap",
                    type: "@appcues/link",
                    config: AppcuesLinkAction.Config(url: URL(string: "https://appcues.com")!, openExternally: nil))
            ],
            level: .step,
            renderContext: .modal,
            interactionType: "Button Tapped",
            viewDescription: "My Button")

        // Assert
        await fulfillment(of: [updateExpectation], timeout: 1)
        let lastUpdate = try XCTUnwrap(mostRecentUpdate)
        guard case .event(name: "appcues:v2:step_interaction", interactive: false) = lastUpdate.type else { return XCTFail() }
        [
            "interactionType": "Button Tapped",
            "interactionData": [
                "category": "link",
                "destination": "https://appcues.com",
                "text": "My Button"
            ]
        ].verifyPropertiesMatch(lastUpdate.properties)
    }

    func testTriggerFlow() async throws {
        // Arrange
        let updateExpectation = expectation(description: "Update set")
        var mostRecentUpdate: TrackingUpdate?
        appcues.analyticsPublisher.onPublish = { update in
            mostRecentUpdate = update
            updateExpectation.fulfill()
        }

        // Act
        actionRegistry.enqueue(
            actionModels: [
                Experience.Action(
                    trigger: "tap",
                    type: "@appcues/link",
                    config: AppcuesLinkAction.Config(url: URL(string: "myapp://deeplink")!, openExternally: nil)),
                Experience.Action(
                    trigger: "tap",
                    type: "@appcues/launch-experience",
                    config: AppcuesLaunchExperienceAction.Config(experienceID: "c1d5336f-6416-4805-9e82-4073c9b8cdb8"))
            ],
            level: .step,
            renderContext: .modal,
            interactionType: "Button Tapped",
            viewDescription: "My Button")

        // Assert
        await fulfillment(of: [updateExpectation], timeout: 1)
        let lastUpdate = try XCTUnwrap(mostRecentUpdate)
        guard case .event(name: "appcues:v2:step_interaction", interactive: false) = lastUpdate.type else { return XCTFail() }
        [
            "interactionType": "Button Tapped",
            "interactionData": [
                "category": "internal",
                "destination": "c1d5336f-6416-4805-9e82-4073c9b8cdb8",
                "text": "My Button"
            ]
        ].verifyPropertiesMatch(lastUpdate.properties)
    }

    func testDismissFlow() async throws {
        // Arrange
        let updateExpectation = expectation(description: "Update set")
        var mostRecentUpdate: TrackingUpdate?
        appcues.analyticsPublisher.onPublish = { update in
            mostRecentUpdate = update
            updateExpectation.fulfill()
        }

        // Act
        actionRegistry.enqueue(
            actionModels: [
                Experience.Action(
                    trigger: "tap",
                    type: "@appcues/close",
                    config: AppcuesCloseAction.Config(markComplete: true))
            ],
            level: .step,
            renderContext: .modal,
            interactionType: "Button Tapped",
            viewDescription: "My Button")

        // Assert
        await fulfillment(of: [updateExpectation], timeout: 1)
        let lastUpdate = try XCTUnwrap(mostRecentUpdate)
        guard case .event(name: "appcues:v2:step_interaction", interactive: false) = lastUpdate.type else { return XCTFail() }
        [
            "interactionType": "Button Tapped",
            "interactionData": [
                "category": "internal",
                "destination": "end-experience",
                "text": "My Button"
            ]
        ].verifyPropertiesMatch(lastUpdate.properties)
    }

    func testGoToCustomStep() async throws {
        // Arrange
        let updateExpectation = expectation(description: "Update set")
        var mostRecentUpdate: TrackingUpdate?
        appcues.analyticsPublisher.onPublish = { update in
            mostRecentUpdate = update
            updateExpectation.fulfill()
        }

        // Act
        actionRegistry.enqueue(
            actionModels: [
                Experience.Action(
                    trigger: "tap",
                    type: "@appcues/continue",
                    config: AppcuesContinueAction.Config(index: nil, offset: nil, stepID: UUID(uuidString: "c1ba5af5-df15-4e38-834b-c7c33ee91e44")))
            ],
            level: .step,
            renderContext: .modal,
            interactionType: "Button Tapped",
            viewDescription: "My Button")

        // Assert
        await fulfillment(of: [updateExpectation], timeout: 1)
        let lastUpdate = try XCTUnwrap(mostRecentUpdate)
        guard case .event(name: "appcues:v2:step_interaction", interactive: false) = lastUpdate.type else { return XCTFail() }
        [
            "interactionType": "Button Tapped",
            "interactionData": [
                "category": "internal",
                "destination": "C1BA5AF5-DF15-4E38-834B-C7C33EE91E44",
                "text": "My Button"
            ]
        ].verifyPropertiesMatch(lastUpdate.properties)
    }

    func testExecuteThrowsWithoutAppcuesInstance() async throws {
        // Arrange
        let action = try XCTUnwrap(AppcuesStepInteractionAction(appcues: nil, renderContext: .modal, interactionType: "String", viewDescription: "String", category: "String", destination: "String"))

        // Act/Assert
        await XCTAssertThrowsAsyncError(try await action.execute()) {
            XCTAssertEqual(($0 as? AppcuesTraitError)?.description, "No appcues instance")
        }
    }
}
