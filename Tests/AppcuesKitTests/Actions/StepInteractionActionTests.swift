//
//  StepInteractionActionTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-10-06.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

@available(iOS 13.0, *)
class StepInteractionActionTests: XCTestCase {

    var appcues: MockAppcues!
    var actionRegistry: ActionRegistry!

    override func setUpWithError() throws {
        appcues = MockAppcues()
        actionRegistry = ActionRegistry(container: appcues.container)
    }

    func testNextStep() throws {
        // Arrange
        var mostRecentUpdate: TrackingUpdate?
        appcues.analyticsPublisher.onPublish = { update in mostRecentUpdate = update }

        // Act
        actionRegistry.enqueue(
            actionModels: [
                Experience.Action(
                    trigger: "tap",
                    type: "@appcues/continue",
                    config: ["offset": 1]),
                Experience.Action(
                    trigger: "tap",
                    type: "@appcues/track",
                    config: ["eventName": "Some event"])
            ],
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
            ]
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
                    config: ["offset": -1]),
                Experience.Action(
                    trigger: "tap",
                    type: "@appcues/track",
                    config: ["eventName": "Some event"])
            ],
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
                    config: ["markComplete":"true"]),
                Experience.Action(
                    trigger: "tap",
                    type: "@appcues/link",
                    config: ["url": "https://appcues.com"])
            ],
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
                    config: ["url": "myapp://deeplink"]),
                Experience.Action(
                    trigger: "tap",
                    type: "@appcues/launch-experience",
                    config: ["experienceID": "c1d5336f-6416-4805-9e82-4073c9b8cdb8"])
            ],
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
                    config: ["markComplete": true])
            ],
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
                    config: ["stepID": "c1ba5af5-df15-4e38-834b-c7c33ee91e44"])
            ],
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
}
