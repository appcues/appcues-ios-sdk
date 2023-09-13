//
//  AppcuesStepInteractionActionTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-10-06.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

@available(iOS 13.0, *)
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

    func testNextStep() throws {
        // Arrange
        var mostRecentUpdate: TrackingUpdate?
        let experience = ExperienceData.mock

        appcues.experienceRenderer.onExperienceData = { _ in
            experience
        }
        appcues.experienceRenderer.onStepIndex = { _ in
            .initial
        }

        appcues.analyticsPublisher.onPublish = { update in mostRecentUpdate = update }

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
                    config: AppcuesTrackAction.Config(eventName: "Some event"))
            ],
            level: .step,
            renderContext: .modal,
            interactionType: "Button Tapped",
            viewDescription: "My Button")

        // Assert
        let lastUpdate = try XCTUnwrap(mostRecentUpdate)
        guard case .event(name: "appcues:v2:step_interaction", interactive: false) = lastUpdate.type else { return XCTFail() }
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
            "stepId": experience.steps[0].items[0].id.appcuesFormatted,
            "stepType": experience.steps[0].items[0].type,
            "stepIndex": "0,0",
            "version": try XCTUnwrap(experience.publishedAt)
        ].verifyPropertiesMatch(lastUpdate.properties)
    }

    func testPreviousStep() throws {
        // Arrange
        var mostRecentUpdate: TrackingUpdate?
        appcues.analyticsPublisher.onPublish = { update in mostRecentUpdate = update }

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
                    config: AppcuesTrackAction.Config(eventName: "Some event"))
            ],
            level: .step,
            renderContext: .modal,
            interactionType: "Button Tapped",
            viewDescription: "My Button")

        // Assert
        let lastUpdate = try XCTUnwrap(mostRecentUpdate)
        guard case .event(name: "appcues:v2:step_interaction", interactive: false) = lastUpdate.type else { return XCTFail() }
        [
            "interactionType": "Button Tapped",
            "interactionData": [
                "category": "internal",
                "destination": "-1",
                "text": "My Button"
            ]
        ].verifyPropertiesMatch(lastUpdate.properties)
    }

    func testGoToLink() throws {
        // Arrange
        var mostRecentUpdate: TrackingUpdate?
        appcues.analyticsPublisher.onPublish = { update in mostRecentUpdate = update }

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

    func testTriggerFlow() throws {
        // Arrange
        var mostRecentUpdate: TrackingUpdate?
        appcues.analyticsPublisher.onPublish = { update in mostRecentUpdate = update }

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

    func testDismissFlow() throws {
        // Arrange
        var mostRecentUpdate: TrackingUpdate?
        appcues.analyticsPublisher.onPublish = { update in mostRecentUpdate = update }

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

    func testGoToCustomStep() throws {
        // Arrange
        var mostRecentUpdate: TrackingUpdate?
        appcues.analyticsPublisher.onPublish = { update in mostRecentUpdate = update }

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

    func testExecuteCompletesWithoutAppcuesInstance() throws {
        // Arrange
        var completionCount = 0
        let action = try XCTUnwrap(AppcuesStepInteractionAction(appcues: nil, renderContext: .modal, interactionType: "String", viewDescription: "String", category: "String", destination: "String"))

        // Act
        action.execute(completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
    }
}
