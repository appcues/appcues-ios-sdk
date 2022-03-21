//
//  ExperienceStateMachineTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-03-18.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class ExperienceStateMachineTests: XCTestCase {

    typealias State = ExperienceStateMachine.State
    typealias Action = ExperienceStateMachine.Action

    var appcues: MockAppcues!

    override func setUpWithError() throws {
        appcues = MockAppcues()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testInitialState() throws {
        // Arrage
        let stateMachine = ExperienceStateMachine(container: appcues.container)

        // Assert
        XCTAssertEqual(stateMachine.state, .idling)
    }

    // MARK: Standard Transitions

    func test_stateIsIdling_whenStartExperience_transitionsToRenderingStep() throws {
        // Precondition
        XCTAssertNil(appcues.storage.lastContentShownAt)

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
            .renderingStep(experience, Experience.StepIndex(group: 0, item: 0), package)
        )
        XCTAssertNotNil(appcues.storage.lastContentShownAt)
        XCTAssertTrue(package.containerController.lifecycleHandler === stateMachine)
    }

    func test_stateIsRenderingStep_whenStartStep_transitionsToRenderingStepInSameGroup() throws {
        // the @appcues/continue action would do this

        // Arrange
        let presentExpectation = expectation(description: "Experience presented")
        presentExpectation.isInverted = true
        let experience = Experience.mock
        let package: ExperiencePackage = experience.package(presentExpectation: presentExpectation)

        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 0), package)
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
            .renderingStep(experience, Experience.StepIndex(group: 0, item: 1), package)
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

        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 1), package)
        let action: Action = .startStep(StepReference.offset(1))
        let stateMachine = givenState(is: initialState)

        // Act
        try stateMachine.transition(action)

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertEqual(
            stateMachine.state,
            .renderingStep(experience, Experience.StepIndex(group: 1, item: 0), package)
        )
    }

    func test_stateIsRenderingStep_whenEndExperience_transitionsToIdling() throws {
        // the @appcues/close action would do this

        // Arrange
        let dismissExpectation = expectation(description: "Experience dismissed")
        let experience = Experience.mock
        let package: ExperiencePackage = experience.package(dismissExpectation: dismissExpectation)

        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 1), package)
        let action: Action = .endExperience
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

        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 1), package)
        let stateMachine = givenState(is: initialState)
        package.containerController.lifecycleHandler = stateMachine

        // Act
        (package.containerController as! MockDefaultContainerViewController).mockIsBeingDismissed = true
        package.containerController.viewWillDisappear(false)
        package.containerController.viewDidDisappear(false)

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertEqual(stateMachine.state, .idling)
    }

    // MARK: Error Transitions

    func test_stateIsIdling_whenStartExperienceWithNoSteps_noTransition() throws {
        // Arrange
        let experience = Experience(id: UUID(), name: "Empty experience", traits: [], steps: [])
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

        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 0), experience.package())
        let action: Action = .startStep(.offset(2)) // start step in a new group
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
        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 1), experience.package())
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
        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 1), experience.package())
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
        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 0), experience.package())
        let action: Action = .reportError(ExperienceStateMachine.ExperienceError.noTransition, fatal: false)
        let stateMachine = givenState(is: initialState)

        // Act
        try stateMachine.transition(action)

        // Assert
        XCTAssertEqual(stateMachine.state, initialState)
    }

    func test_stateIsRenderingStep_whenReportFatalError_transitionsToIdling() throws {
        // Arrange
        let experience = Experience.mock
        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 0), experience.package())
        let action: Action = .reportError(ExperienceStateMachine.ExperienceError.noTransition, fatal: true)
        let stateMachine = givenState(is: initialState)

        // Act
        try stateMachine.transition(action)

        // Assert
        XCTAssertEqual(stateMachine.state, .idling)
    }


    func test_stateIsRenderingStep_whenReset_noTransition() throws {
        // Invalid action for given state

        // Arrange
        let experience = Experience.mock
        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 0), experience.package())
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

class MockAppcuesExperienceDelegate: AppcuesExperienceDelegate {
    var canDisplay: Bool

    init(canDisplay: Bool) {
        self.canDisplay = canDisplay
    }

    func canDisplayExperience(experienceID: String) -> Bool {
        canDisplay
    }
}

private extension Experience {
    static var mock: Experience {
        Experience(
            id: UUID(uuidString: "54b7ec71-cdaf-4697-affa-f3abd672b3cf")!,
            name: "test",
            traits: [],
            steps: [
                .group(Step.Group(
                    id: UUID(uuidString: "39713d1b-fdd8-4438-a992-e7ff1b698056")!,
                    children: [
                        Step.Child(fixedID: "fb529214-3c78-4d6d-ba93-b55d22497ca1"),
                        Step.Child(fixedID: "9c56d7b9-5f84-498d-9ace-210b10b90e87")
                    ],
                    traits: [],
                    actions: [:])),
                .child(Step.Child(fixedID: "e03ae132-91b7-4cb0-9474-7d4a0e308a07"))
            ])
    }

    func package(presentExpectation: XCTestExpectation? = nil, dismissExpectation: XCTestExpectation? = nil) -> ExperiencePackage {
        let containerController = MockDefaultContainerViewController(stepControllers: [UIViewController(), UIViewController()])
        return ExperiencePackage(
            traitInstances: [],
            steps: self.steps[0].items,
            containerController: containerController,
            wrapperController: containerController,
            presenter: {
                containerController.mockIsBeingPresented = true
                containerController.lifecycleHandler?.containerWillAppear()
                containerController.lifecycleHandler?.containerDidAppear()
                containerController.mockIsBeingPresented = false
                presentExpectation?.fulfill()
                $0?()
            },
            dismisser: {
                containerController.mockIsBeingDismissed = true
                containerController.lifecycleHandler?.containerWillDisappear()
                containerController.lifecycleHandler?.containerDidDisappear()
                containerController.mockIsBeingDismissed = false
                dismissExpectation?.fulfill()
                $0?()
            })
    }
}

private class MockDefaultContainerViewController: DefaultContainerViewController {
    // ExperienceStateMachine checks these values to avoid unnecessary lifecycle events,
    // and so we need to mock them to trigger the correct events

    var mockIsBeingPresented = false
    override var isBeingPresented: Bool { mockIsBeingPresented }

    var mockIsBeingDismissed = false
    override var isBeingDismissed: Bool { mockIsBeingDismissed }

    override func navigate(to pageIndex: Int, animated: Bool) {
        pageMonitor.set(currentPage: pageIndex)
    }
}
