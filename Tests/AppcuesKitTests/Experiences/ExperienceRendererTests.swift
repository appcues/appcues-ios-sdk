//
//  ExperienceRendererTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-02-07.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class ExperienceRendererTests: XCTestCase {

    var appcues: MockAppcues!
    var experienceRenderer: ExperienceRenderer!

    override func setUpWithError() throws {
        appcues = MockAppcues()
        experienceRenderer = ExperienceRenderer(container: appcues.container)
    }

    @MainActor
    func testShowPublished() async throws {
        // Arrange
        let presentExpectation = expectation(description: "Experience presented")
        let experience = ExperienceData.mock
        let preconditionPackage: ExperiencePackage = experience.package(presentExpectation: presentExpectation)
        appcues.traitComposer.setPackage { _, _ in preconditionPackage }


        let eventExpectation = expectation(description: "event tracked")
        // expect some number of analytics events (events/states are tested elsewhere)
        eventExpectation.assertForOverFulfill = false
        appcues.analyticsPublisher.onPublish = { _ in eventExpectation.fulfill() }

        // Act
        try await experienceRenderer.processAndShow(experience: ExperienceData(experience.model, trigger: .showCall, priority: .low, published: true))

        // Assert
        await fulfillment(of: [presentExpectation, eventExpectation], timeout: 1)
    }

    @MainActor
    func testShowPublishedNormalPriorityReplacesExisting() async throws {
        // Arrange
        // Two experiences should be presented
        let presentExpectation = expectation(description: "Experience presented")
        presentExpectation.expectedFulfillmentCount = 2
        let dismissExpectation = expectation(description: "Experience dismissed")
        // Experiences with different instanceIDs
        let experience1 = ExperienceData.mock
        let experience2 = ExperienceData.mock
        let preconditionPackage: ExperiencePackage = experience1.package(
            presentExpectation: presentExpectation,
            dismissExpectation: dismissExpectation)
        appcues.traitComposer.setPackage { _, _ in preconditionPackage }

        // Set up first experience
        try await experienceRenderer.processAndShow(experience: ExperienceData(experience1.model, trigger: .showCall, priority: .low, published: true))

        // Act
        try await experienceRenderer.processAndShow(experience: ExperienceData(experience2.model, trigger: .showCall, priority: .normal, published: true))

        // Assert
        await fulfillment(of: [dismissExpectation, presentExpectation], timeout: 1)
    }

    @MainActor
    func testShowPublishedLowPriorityDoesntReplaceExisting() async throws {
        // Arrange
        let presentExpectation = expectation(description: "Experience presented")
        let failureExpectation = expectation(description: "Experience presentation failed called")
        // Experiences with different instanceIDs
        let experience1 = ExperienceData.mock
        let experience2 = ExperienceData.mock
        let preconditionPackage: ExperiencePackage = experience1.package(presentExpectation: presentExpectation)
        appcues.traitComposer.setPackage { _, _ in preconditionPackage }

        // Set up first experience
        try await experienceRenderer.processAndShow(experience: ExperienceData(experience1.model, trigger: .showCall, priority: .low, published: true))
        await fulfillment(of: [presentExpectation], timeout: 1)

        // Act
        do {
            try await experienceRenderer.processAndShow(experience: ExperienceData(experience2.model, trigger: .showCall, priority: .low, published: true))
        } catch ExperienceStateMachine.ExperienceError.experienceAlreadyActive {
            failureExpectation.fulfill()
        }

        await fulfillment(of: [failureExpectation], timeout: 1)
    }

    @MainActor
    func testShowPublishedSameInstanceDoesntReplaceExisting() async throws {
        // Arrange
        let presentExpectation = expectation(description: "Experience presented")
        let dismissExpectation = expectation(description: "Experience dismissed")
        // No experience should be dismissed because we're showing the same instance
        dismissExpectation.isInverted = true
        let experience = ExperienceData.mock
        let preconditionPackage: ExperiencePackage = experience.package(
            presentExpectation: presentExpectation,
            dismissExpectation: dismissExpectation)
        appcues.traitComposer.setPackage { _, _ in preconditionPackage }

        // Set up first experience
        try await experienceRenderer.processAndShow(experience: ExperienceData(experience.model, trigger: .showCall, priority: .low, published: true))

        // Act
        try await experienceRenderer.processAndShow(experience: ExperienceData(experience.model, trigger: .showCall, priority: .normal, published: true))

        // Assert
        await fulfillment(of: [dismissExpectation, presentExpectation], timeout: 1, enforceOrder: true)
    }

    @MainActor
    func testShowUnpublished() async throws {
        // Arrange
        let presentExpectation = expectation(description: "Experience presented")
        let experience = ExperienceData.mock
        let preconditionPackage: ExperiencePackage = experience.package(presentExpectation: presentExpectation)
        appcues.traitComposer.setPackage { _, _ in preconditionPackage }

        let eventExpectation = expectation(description: "event tracked")
        // no analytics events should be tracked because this is an unpublished flow
        eventExpectation.isInverted = true
        appcues.analyticsPublisher.onPublish = { _ in eventExpectation.fulfill() }

        // Act
        try await experienceRenderer.processAndShow(experience: ExperienceData(experience.model, trigger: .showCall, priority: .low, published: false))

        // Assert
        await fulfillment(of: [presentExpectation, eventExpectation], timeout: 1, enforceOrder: true)
    }

    @MainActor
    func testShowQualifiedExperiences() async throws {
        // Arrange
        let presentExpectation = expectation(description: "Experience presented")

        let brokenExperience = ExperienceData.mock
        let validExperience = ExperienceData.mock
        let preconditionPackage: ExperiencePackage = validExperience.package(presentExpectation: presentExpectation)
        appcues.traitComposer.setPackage { experience, _ in
            if experience.instanceID == validExperience.instanceID {
                return preconditionPackage
            } else {
                throw AppcuesTraitError(description: "Presenting capability trait required")
            }
        }

        let eventExpectation = expectation(description: "event tracked")
        // expect at least 2 analytics events (events/states are tested elsewhere)
        eventExpectation.expectedFulfillmentCount = 2
        eventExpectation.assertForOverFulfill = false
        appcues.analyticsPublisher.onPublish = { _ in eventExpectation.fulfill() }

        // Act
        try await experienceRenderer.processAndShow(qualifiedExperiences: [
            ExperienceData(brokenExperience.model, trigger: .qualification(reason: .screenView), priority: .low),
            ExperienceData(validExperience.model, trigger: .qualification(reason: .screenView), priority: .low)
        ], reason: .qualification(reason: .screenView))

        // Assert
        await fulfillment(of: [presentExpectation, eventExpectation], timeout: 1, enforceOrder: true)
    }

    @MainActor
    func testShowStepReference() async throws {
        // Arrange
        let experience = ExperienceData.mock
        var preconditionPackage: ExperiencePackage = experience.package()
        appcues.traitComposer.setPackage { _, _ in preconditionPackage }
        try await experienceRenderer.processAndShow(experience: ExperienceData(experience.model, trigger: .showCall, priority: .low, published: true))

        // Now that we've shown the first step, set the expectation for the 2nd step transition that we're testing
        let presentExpectation = expectation(description: "Experience presented")
        preconditionPackage = experience.package(presentExpectation: presentExpectation)

        // Step ID in a different container
        let targetID = try XCTUnwrap(UUID(uuidString: "03652bd5-f0cb-44f0-9274-e95b4441d857"))

        // Act
        try await experienceRenderer.show(step: .stepID(targetID), inContext: .modal)

        // Assert
        await fulfillment(of: [presentExpectation], timeout: 1)
    }

    @MainActor
    func testDismissExperience() async throws {
        // Arrange
        let dismissExpectation = expectation(description: "Experience dismissed")
        let experience = ExperienceData.mock
        let preconditionPackage: ExperiencePackage = experience.package(dismissExpectation: dismissExpectation)
        appcues.traitComposer.setPackage { _, _ in preconditionPackage }
        try await experienceRenderer.processAndShow(experience: ExperienceData(experience.model, trigger: .showCall, priority: .low, published: true))

        // Act
        try await experienceRenderer.dismiss(inContext: .modal, markComplete: false)

        // Assert
        await fulfillment(of: [dismissExpectation], timeout: 1)
    }

    @MainActor
    func testDismissExperienceLastStep() async throws {
        // Arrange
        var updates: [TrackingUpdate] = []
        let dismissExpectation = expectation(description: "Experience dismissed")
        let experience = ExperienceData.singleStepMock
        let preconditionPackage: ExperiencePackage = experience.package(dismissExpectation: dismissExpectation)
        appcues.traitComposer.setPackage { _, _ in preconditionPackage }
        try await experienceRenderer.processAndShow(experience: ExperienceData(experience.model, trigger: .showCall, priority: .low, published: true))
        appcues.analyticsPublisher.onPublish = { update in updates.append(update) }

        // Act
        try await experienceRenderer.dismiss(inContext: .modal, markComplete: false)

        // Assert
        await fulfillment(of: [dismissExpectation], timeout: 1)
        let lastUpdate = try XCTUnwrap(updates.last)
        // confirm that dismiss on last step triggers experience_dismissed analytics, not experience_completed
        XCTAssertEqual(lastUpdate.type, .event(name: "appcues:v2:experience_dismissed", interactive: false))
    }

    @MainActor
    func testShowSameExperienceFromTwoSources() async throws {
        // Test that the state machine observers can properly distinguish between the same experience ID.

        // Arrange
        let failureExpectation = expectation(description: "Second experience: failure called")
        let presentExpectation = expectation(description: "Experience presented")
        let firstExperienceInstance = ExperienceData.mock
        let secondExperienceInstance = ExperienceData.mock
        let preconditionPackage: ExperiencePackage = firstExperienceInstance.packageWithDelay(presentExpectation: presentExpectation)
        appcues.traitComposer.setPackage { _, _ in preconditionPackage }

        // Act
        try await experienceRenderer.processAndShow(experience: ExperienceData(firstExperienceInstance.model, trigger: .showCall, priority: .low, published: true))

        do {
            try await experienceRenderer.processAndShow(experience: ExperienceData(secondExperienceInstance.model, trigger: .showCall, priority: .low, published: true))
        } catch {
            XCTAssertEqual(
                error as! ExperienceStateMachine.ExperienceError,
                ExperienceStateMachine.ExperienceError.experienceAlreadyActive(ignoredExperience: secondExperienceInstance)
            )
            failureExpectation.fulfill()
        }

        // Assert
        XCTAssertEqual(firstExperienceInstance.id, secondExperienceInstance.id)
        XCTAssertNotEqual(firstExperienceInstance.instanceID, secondExperienceInstance.instanceID)
        await fulfillment(of: [presentExpectation, failureExpectation], timeout: 1)
    }

    @MainActor
    func testShowStepDismissCallsCompletion() async throws {
        // sc-38212: Test that the completion handler is called when continuing from
        // last step in an experience (which dismisses the experience).

        // Arrange
        let dismissExpectation = expectation(description: "Experience dismissed")

        let preconditionPresentExpectation = expectation(description: "Experience presented")
        let experience = ExperienceData.singleStepMock
        let preconditionPackage: ExperiencePackage = experience.package(presentExpectation: preconditionPresentExpectation, dismissExpectation: dismissExpectation)
        appcues.traitComposer.setPackage { _, _ in preconditionPackage }
        try await experienceRenderer.processAndShow(experience: ExperienceData(experience.model, trigger: .showCall, priority: .low, published: true))
        await fulfillment(of: [preconditionPresentExpectation], timeout: 1)

        // Act
        try await experienceRenderer.show(step: .offset(1), inContext: .modal)

        // Assert
        await fulfillment(of: [dismissExpectation], timeout: 1)
    }

    @MainActor
    func testShowControlExperimentFail() async throws {
        // Arrange
        let failureExpectation = expectation(description: "Failure completion called")
        let presentExpectation = expectation(description: "Experience presented")
        presentExpectation.isInverted = true
        let experience = ExperienceData.singleStepMock
        let experimentID = UUID(uuidString: "6ce90d1d-4de2-41a6-bc93-07ae23b728c5")!
        let experiment = Experiment(group: "control", experimentID: experimentID, experienceID: experience.id, goalID: "my-goal", contentType: "my-content-type")
        let preconditionPackage: ExperiencePackage = experience.package(presentExpectation: presentExpectation)
        appcues.traitComposer.setPackage { _, _ in preconditionPackage }

        // Act
        do {
            try await experienceRenderer.processAndShow(experience: ExperienceData(experience.model, trigger: .showCall, priority: .low, published: true, experiment: experiment))
        } catch ExperienceRendererError.experimentControl {
            failureExpectation.fulfill()
        }

        // Assert
        await fulfillment(of: [presentExpectation, failureExpectation], timeout: 1)
    }

    @MainActor
    func testShowExposedExperiment() async throws {
        // Arrange
        let presentExpectation = expectation(description: "Experience presented")
        let experience = ExperienceData.singleStepMock
        let experimentID = UUID(uuidString: "6ce90d1d-4de2-41a6-bc93-07ae23b728c5")!
        let experiment = Experiment(group: "exposed", experimentID: experimentID, experienceID: experience.id, goalID: "my-goal", contentType: "my-content-type")
        let preconditionPackage: ExperiencePackage = experience.package(presentExpectation: presentExpectation)
        appcues.traitComposer.setPackage { _, _ in preconditionPackage }

        // Act
        try await experienceRenderer.processAndShow(experience: ExperienceData(experience.model, trigger: .showCall, priority: .low, published: true, experiment: experiment))

        // Assert
        await fulfillment(of: [presentExpectation], timeout: 1)
    }

    @MainActor
    func testExperimentEnteredControlAnalytics() async throws {
        // Arrange
        let failureExpectation = expectation(description: "Failure completion called")
        let analyticsExpectation = expectation(description: "Triggered experiment_entered analytics")
        let experience = ExperienceData.singleStepMock
        let experimentID = UUID(uuidString: "6ce90d1d-4de2-41a6-bc93-07ae23b728c5")!
        let experiment = Experiment(group: "control", experimentID: experimentID, experienceID: experience.id, goalID: "my-goal", contentType: "my-content-type")
        let properties: [String: Any] = [
            "experimentId": experimentID.appcuesFormatted,
            "experimentGroup": "control",
            "experimentExperienceId": experience.id.appcuesFormatted,
            "experimentGoalId": "my-goal",
            "experimentContentType": "my-content-type"
        ]
        var experimentUpdate: TrackingUpdate?
        appcues.analyticsPublisher.onPublish = { update in
            if case let .event(name, interactive) = update.type,
                name == "appcues:experiment_entered",
                !interactive {
                experimentUpdate = update
                analyticsExpectation.fulfill()
            }
        }

        // Act
        do {
            try await experienceRenderer.processAndShow(experience: ExperienceData(experience.model, trigger: .showCall, priority: .low, published: true, experiment: experiment))
        } catch ExperienceRendererError.experimentControl {
            failureExpectation.fulfill()
        }

        // Assert
        await fulfillment(of: [failureExpectation, analyticsExpectation], timeout: 1)
        properties.verifyPropertiesMatch(experimentUpdate?.properties)
    }

    @MainActor
    func testExperimentEnteredExposedAnalytics() async throws {
        // Arrange
        let analyticsExpectation = expectation(description: "Triggered experiment_entered analytics")
        let presentExpectation = expectation(description: "Experience presented")
        let experience = ExperienceData.singleStepMock
        let preconditionPackage: ExperiencePackage = experience.package(presentExpectation: presentExpectation)
        appcues.traitComposer.setPackage { _, _ in preconditionPackage }
        let experimentID = UUID(uuidString: "6ce90d1d-4de2-41a6-bc93-07ae23b728c5")!
        let experiment = Experiment(group: "exposed", experimentID: experimentID, experienceID: experience.id, goalID: "my-goal", contentType: "my-content-type")
        let properties: [String: Any] = [
            "experimentId": experimentID.appcuesFormatted,
            "experimentGroup": "exposed",
            "experimentExperienceId": experience.id.appcuesFormatted,
            "experimentGoalId": "my-goal",
            "experimentContentType": "my-content-type"
        ]
        var experimentUpdate: TrackingUpdate?
        appcues.analyticsPublisher.onPublish = { update in
            if case let .event(name, interactive) = update.type,
                name == "appcues:experiment_entered",
                !interactive {
                experimentUpdate = update
                analyticsExpectation.fulfill()
            }
        }

        // Act
        try await experienceRenderer.processAndShow(experience: ExperienceData(experience.model, trigger: .showCall, priority: .low, published: true, experiment: experiment))

        // Assert
        await fulfillment(of: [analyticsExpectation, presentExpectation], timeout: 1, enforceOrder: true)
        properties.verifyPropertiesMatch(experimentUpdate?.properties)
    }

    @MainActor
    func testReset() async throws {
        let preconditionPresentExpectation = expectation(description: "Experience presented")
        let dismissExpectation = expectation(description: "Experience dismissed")
        let experience = ExperienceData.mock
        let preconditionPackage: ExperiencePackage = experience.package(presentExpectation: preconditionPresentExpectation, dismissExpectation: dismissExpectation)
        appcues.traitComposer.setPackage { _, _ in preconditionPackage }
        try await experienceRenderer.processAndShow(experience: ExperienceData(experience.model, trigger: .showCall, priority: .low, published: true))
        await fulfillment(of: [preconditionPresentExpectation], timeout: 1)

        appcues.analyticsPublisher.onPublish = { update in
            XCTFail("no analytics expected")
        }

        // Act
        await experienceRenderer.resetAll()

        // Assert
        await fulfillment(of: [dismissExpectation], timeout: 1, enforceOrder: true)
    }
}

private extension ExperienceData {
    func packageWithDelay(presentExpectation: XCTestExpectation? = nil, dismissExpectation: XCTestExpectation? = nil) -> ExperiencePackage {
        let pageMonitor = AppcuesExperiencePageMonitor(numberOfPages: 1, currentPage: 0)
        let containerController = Mocks.ContainerViewController(stepControllers: [UIViewController()], pageMonitor: pageMonitor)
        return ExperiencePackage(
            traitInstances: [],
            stepDecoratingTraitUpdater: { new, prev in },
            steps: self.steps[0].items,
            containerController: containerController,
            wrapperController: containerController,
            pageMonitor: pageMonitor,
            presenter: {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                presentExpectation?.fulfill()
            },
            dismisser: {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                dismissExpectation?.fulfill()
            })
    }
}
