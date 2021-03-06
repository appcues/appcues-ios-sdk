//
//  ExperienceStateMachineTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-03-18.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

@available(iOS 13.0, *)
class ExperienceStateMachineTests: XCTestCase {

    typealias State = ExperienceStateMachine.State
    typealias Action = ExperienceStateMachine.Action

    var appcues: MockAppcues!

    override func setUpWithError() throws {
        appcues = MockAppcues()
    }

    func testInitialState() throws {
        // Arrage
        let stateMachine = ExperienceStateMachine(container: appcues.container)

        // Assert
        XCTAssertEqual(stateMachine.state, .idling)
    }

    // MARK: Standard Transitions

    func test_stateIsIdling_whenStartExperience_transitionsToRenderingStep() throws {
        // Arrange
        let presentExpectation = expectation(description: "Experience presented")
        let experience = Experience.mock
        let package: ExperiencePackage = experience.package(presentExpectation: presentExpectation)
        appcues.traitComposer.onPackage = { _, stepIndex in
            XCTAssertEqual(stepIndex, Experience.StepIndex(group: 0, item: 0))
            return package
        }

        let initialState: State = .idling
        let action: Action = .startExperience(experience)
        let stateMachine = givenState(is: initialState)

        // Act
        try stateMachine.transition(action)

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertEqual(
            stateMachine.state,
            .renderingStep(experience, Experience.StepIndex(group: 0, item: 0), package, isFirst: true)
        )
        XCTAssertTrue(package.containerController.lifecycleHandler === stateMachine)
    }

    func test_stateIsRenderingStep_whenStartStep_transitionsToRenderingStepInSameGroup() throws {
        // the @appcues/continue action would do this

        // Arrange
        let presentExpectation = expectation(description: "Experience presented")
        presentExpectation.isInverted = true
        let experience = Experience.mock
        let package: ExperiencePackage = experience.package(presentExpectation: presentExpectation)

        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 0), package, isFirst: false)
        let action: Action = .startStep(StepReference.offset(1))
        let stateMachine = givenState(is: initialState)

        // This would be set in the initial presentation of the group container, but we've skipped over that by setting
        // the initial state of the machine. This is relied upon so the containerController can notify the state machine
        // of the completed change. This being properly set is tested in
        // test_stateIsIdling_whenStartExperience_transitionsToRenderingStep
        package.containerController.lifecycleHandler = stateMachine

        // Act
        try stateMachine.transition(action)

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertEqual(
            stateMachine.state,
            .renderingStep(experience, Experience.StepIndex(group: 0, item: 1), package, isFirst: false)
        )
    }

    func test_stateIsRenderingStep_whenStartStep_transitionsToRenderingStepInNewGroup() throws {
        // the @appcues/continue action would do this

        // Arrange
        let presentExpectation = expectation(description: "Experience presented")
        let experience = Experience.mock
        let package: ExperiencePackage = experience.package(presentExpectation: presentExpectation)
        appcues.traitComposer.onPackage = { _, stepIndex in
            XCTAssertEqual(stepIndex, Experience.StepIndex(group: 1, item: 0))
            return package
        }

        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 2), package, isFirst: false)
        let action: Action = .startStep(StepReference.offset(1))
        let stateMachine = givenState(is: initialState)

        // Act
        try stateMachine.transition(action)

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertEqual(
            stateMachine.state,
            .renderingStep(experience, Experience.StepIndex(group: 1, item: 0), package, isFirst: false)
        )
    }

    func test_stateIsRenderingStep_whenStartStepPastEnd_transitionsToIdling() throws {
        // the @appcues/continue action would do this

        // Arrange
        let dismissExpectation = expectation(description: "Experience dismissed")
        let experience = Experience.mock
        let package: ExperiencePackage = experience.package(dismissExpectation: dismissExpectation)

        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 1, item: 0), package, isFirst: false)
        let action: Action = .startStep(StepReference.offset(1))
        let stateMachine = givenState(is: initialState)

        // Act
        try stateMachine.transition(action)

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertEqual(stateMachine.state, .idling)
    }

    func test_stateIsRenderingStep_whenEndExperience_transitionsToIdling() throws {
        // the @appcues/close action would do this

        // Arrange
        let dismissExpectation = expectation(description: "Experience dismissed")
        let experience = Experience.mock
        let package: ExperiencePackage = experience.package(dismissExpectation: dismissExpectation)

        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 1), package, isFirst: false)
        let action: Action = .endExperience(markComplete: false)
        let stateMachine = givenState(is: initialState)

        // Act
        try stateMachine.transition(action)

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertEqual(stateMachine.state, .idling)
    }

    func test_stateIsRenderingStep_onViewControllerDismissed_transitionsToIdling() throws {
        // the @appcues/skippable trait would do this

        // Arrange
        let dismissExpectation = expectation(description: "Experience dismissed")
        let experience = Experience.mock
        let package: ExperiencePackage = experience.package(dismissExpectation: dismissExpectation)

        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 1), package, isFirst: false)
        let stateMachine = givenState(is: initialState)
        package.containerController.lifecycleHandler = stateMachine

        // Act
        (package.containerController as! Mocks.ContainerViewController).mockIsBeingDismissed = true
        package.containerController.viewWillDisappear(false)
        package.containerController.viewDidDisappear(false)

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertEqual(stateMachine.state, .idling)
    }

    func test_whenEndExperience_andMarkComplete_executesActions() throws {
        // Arrange
        appcues.sessionID = UUID() // needed to pass a check to show the next experience

        let dismissExpectation = expectation(description: "Experience dismissed")
        let nextContentLoadedExpectation = expectation(description: "Next content ID requested")
        let experience = Experience.mock
        let package: ExperiencePackage = experience.package(dismissExpectation: dismissExpectation)

        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 1), package, isFirst: false)
        let action: Action = .endExperience(markComplete: true)
        let stateMachine = givenState(is: initialState)

        appcues.experienceLoader.onLoad = { contentID, published, completion in
            XCTAssertEqual(contentID, Experience.mock.nextContentID)
            XCTAssertTrue(published)
            nextContentLoadedExpectation.fulfill()
            completion?(.success(()))
        }

        // Act
        try stateMachine.transition(action)

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertEqual(stateMachine.state, .idling)
    }

    func test_whenEndExperience_andNoMarkComplete_doesNotExecuteActions() throws {
        // Arrange
        appcues.sessionID = UUID() // needed to pass a check to show the next experience

        let dismissExpectation = expectation(description: "Experience dismissed")
        let nextContentLoadedExpectation = expectation(description: "Next content ID requested")
        nextContentLoadedExpectation.isInverted = true
        let experience = Experience.mock
        let package: ExperiencePackage = experience.package(dismissExpectation: dismissExpectation)

        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 1), package, isFirst: false)
        let action: Action = .endExperience(markComplete: false)
        let stateMachine = givenState(is: initialState)

        appcues.experienceLoader.onLoad = { contentID, published, completion in
            XCTFail("no next content should be shown")
        }

        // Act
        try stateMachine.transition(action)

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertEqual(stateMachine.state, .idling)
    }

    // MARK: Error Transitions

    func test_stateIsIdling_whenStartExperienceWithNoSteps_noTransition() throws {
        // Arrange
        let experience = Experience(id: UUID(), name: "Empty experience", type: "mobile", publishedAt: 1632142800000, traits: [], steps: [], redirectURL: nil, nextContentID: nil)
        let initialState: State = .idling
        let action: Action = .startExperience(experience)
        let stateMachine = givenState(is: initialState)

        // Act
        try stateMachine.transition(action)

        // Assert
        XCTAssertEqual(stateMachine.state, initialState)
    }

    func test_stateIsIdling_whenStartExperienceDelegateBlocks_noTransition() throws {
        // Arrange
        let experience = Experience.mock
        appcues.traitComposer.onPackage = { _, _ in experience.package() }

        let initialState: State = .idling
        let action: Action = .startExperience(experience)
        let stateMachine = givenState(is: initialState)

        let mockDelegate = MockAppcuesExperienceDelegate(canDisplay: false)
        stateMachine.clientAppcuesDelegate = mockDelegate

        // Act
        try stateMachine.transition(action)

        // Assert
        XCTAssertEqual(stateMachine.state, initialState)
    }

    func test_stateIsIdling_whenStartExperiencePackageFails_transitionsToIdling() throws {
        // Arrange
        let experience = Experience.mock
        appcues.traitComposer.onPackage = { _, stepIndex in
            throw TraitError(description: "Presenting capability trait required")
        }

        let initialState: State = .idling
        let action: Action = .startExperience(experience)
        let stateMachine = givenState(is: initialState)

        // Act
        try stateMachine.transition(action)

        // Assert
        XCTAssertEqual(
            stateMachine.state,
            .idling
        )
    }

    func test_stateIsRenderingStep_whenStartStepPackageFails_transitionsToIdling() throws {
        // Arrange
        let experience = Experience.mock
        appcues.traitComposer.onPackage = { _, stepIndex in
            throw TraitError(description: "Presenting capability trait required")
        }

        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 0), experience.package(), isFirst: false)
        // Step ID in a different container
        let targetID = try XCTUnwrap(UUID(uuidString: "03652bd5-f0cb-44f0-9274-e95b4441d857"))
        let action: Action = .startStep(.stepID(targetID))
        let stateMachine = givenState(is: initialState)

        // Act
        try stateMachine.transition(action)

        // Assert
        XCTAssertEqual(
            stateMachine.state,
            .idling
        )
    }


    func test_stateIsRenderingStep_whenStartExperience_noTransition() throws {
        // Arrange
        let experience = Experience.mock
        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 1), experience.package(), isFirst: false)
        let action: Action = .startExperience(Experience.mock)
        let stateMachine = givenState(is: initialState)

        // Act
        try stateMachine.transition(action)

        // Assert
        XCTAssertEqual(stateMachine.state, initialState)
    }

    func test_stateIsRenderingStep_whenStartStepInvalid_noTransition() throws {
        // Arrange
        let experience = Experience.mock
        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 1), experience.package(), isFirst: false)
        let action: Action = .startStep(StepReference.index(1000))
        let stateMachine = givenState(is: initialState)

        // Act
        try stateMachine.transition(action)

        // Assert
        XCTAssertEqual(stateMachine.state, initialState)
    }

    func test_stateIsEndingStep_whenStartStepInvalid_noTransition() throws {
        // Note: in actual usage, the invalid StepReference should be caught before transitioning to .endingStep
        // (see test_stateIsRenderingStep_whenStartStepInvalid_noTransition above)

        // Arrange
        let experience = Experience.mock
        let initialState: State = .endingStep(experience, Experience.StepIndex(group: 0, item: 1), experience.package())
        let action: Action = .startStep(StepReference.index(1000))
        let stateMachine = givenState(is: initialState)

        // Act
        try stateMachine.transition(action)

        // Assert
        XCTAssertEqual(stateMachine.state, initialState)
    }
    func test_stateIsRenderingStep_whenReportNonFatalError_noTransition() throws {
        // Arrange
        let experience = Experience.mock
        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 0), experience.package(), isFirst: false)
        let action: Action = .reportError(ExperienceStateMachine.ExperienceError.noTransition(currentState: initialState), fatal: false)
        let stateMachine = givenState(is: initialState)

        // Act
        try stateMachine.transition(action)

        // Assert
        XCTAssertEqual(stateMachine.state, initialState)
    }

    func test_stateIsRenderingStep_whenReportFatalError_transitionsToIdling() throws {
        // Arrange
        let experience = Experience.mock
        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 0), experience.package(), isFirst: false)
        let action: Action = .reportError(ExperienceStateMachine.ExperienceError.noTransition(currentState: initialState), fatal: true)
        let stateMachine = givenState(is: initialState)

        // Act
        try stateMachine.transition(action)

        // Assert
        XCTAssertEqual(stateMachine.state, .idling)
    }

    func testFatalExperienceErrorNotifiesObserver() throws {
        // Arrange
        let experience = Experience.mock
        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 0), experience.package(), isFirst: false)
        let action: Action = .reportError(ExperienceStateMachine.ExperienceError.noTransition(currentState: initialState), fatal: true)
        let stateMachine = givenState(is: initialState)
        let listingObserver = ListingObserver()
        stateMachine.addObserver(listingObserver)

        // Act
        try stateMachine.transition(action)

        // Assert
        XCTAssertEqual(
            stateMachine.state,
            .idling
        )
        XCTAssertEqual(
            listingObserver.results,
            [
                .failure(.noTransition(currentState: initialState)),
                .success(.idling)
            ]
        )
        XCTAssertEqual(stateMachine.stateObservers.count, 0, "observer is removed when reset to idling")
    }

    func test_stateIsRenderingStep_whenReset_noTransition() throws {
        // Invalid action for given state

        // Arrange
        let experience = Experience.mock
        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 0), experience.package(), isFirst: false)
        let action: Action = .reset
        let stateMachine = givenState(is: initialState)

        // Act/Assert
        XCTAssertThrowsError(try stateMachine.transition(action))
        XCTAssertEqual(stateMachine.state, initialState)
    }

    // MARK: - Helpers

    func givenState(is state: ExperienceStateMachine.State) -> ExperienceStateMachine {
        let stateMachine = ExperienceStateMachine(container: appcues.container, initialState: state)
        XCTAssertEqual(stateMachine.state, state)
        return stateMachine
    }

}

private class MockAppcuesExperienceDelegate: AppcuesExperienceDelegate {
    var canDisplay: Bool

    init(canDisplay: Bool) {
        self.canDisplay = canDisplay
    }

    func canDisplayExperience(experienceID: String) -> Bool {
        canDisplay
    }

    func experienceWillAppear() {}
    func experienceDidAppear() {}
    func experienceWillDisappear() {}
    func experienceDidDisappear() {}
}

private class ListingObserver: ExperienceStateObserver {
    var results: [StateResult] = []
    func evaluateIfSatisfied(result: StateResult) -> Bool {
        results.append(result)
        return false
    }
}
