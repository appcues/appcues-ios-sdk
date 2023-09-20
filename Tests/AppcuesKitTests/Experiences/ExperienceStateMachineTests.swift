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
        let experience = ExperienceData.mock
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
        XCTAssertTrue(package.containerController.eventHandler === stateMachine)
    }

    func test_stateIsRenderingStep_whenStartStep_transitionsToRenderingStepInSameGroup() throws {
        // the @appcues/continue action would do this

        // Arrange
        let presentExpectation = expectation(description: "Experience presented")
        presentExpectation.isInverted = true
        let experience = ExperienceData.mock
        let package: ExperiencePackage = experience.package(presentExpectation: presentExpectation)

        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 0), package, isFirst: false)
        let action: Action = .startStep(StepReference.offset(1))
        let stateMachine = givenState(is: initialState)

        // This would be set in the initial presentation of the group container, but we've skipped over that by setting
        // the initial state of the machine. This is relied upon so the containerController can notify the state machine
        // of the completed change. This being properly set is tested in
        // test_stateIsIdling_whenStartExperience_transitionsToRenderingStep
        package.containerController.eventHandler = stateMachine
        package.pageMonitor.addObserver { newIndex, oldIndex in
            stateMachine.containerNavigated(from: oldIndex, to: newIndex)
        }

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
        let experience = ExperienceData.mock
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
        let experience = ExperienceData.mock
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
        let experience = ExperienceData.mock
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
        let experience = ExperienceData.mock
        let package: ExperiencePackage = experience.package(dismissExpectation: dismissExpectation)

        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 1), package, isFirst: false)
        let stateMachine = givenState(is: initialState)
        package.containerController.eventHandler = stateMachine

        // Act
        (package.containerController as! Mocks.ContainerViewController).mockIsBeingDismissed = true
        package.containerController.viewWillDisappear(false)
        package.containerController.viewDidDisappear(false)

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertEqual(stateMachine.state, .idling)
    }

    func test_stateIsRenderingStep_onViewControllerDismissed_doesNotMarkComplete() throws {
        // the @appcues/skippable trait would do this

        // Arrange
        var updates: [TrackingUpdate] = []
        let dismissExpectation = expectation(description: "Experience dismissed")
        let experience = ExperienceData.mock
        let package: ExperiencePackage = experience.package(dismissExpectation: dismissExpectation)

        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 1, item: 0), package, isFirst: true)
        let stateMachine = givenState(is: initialState)
        package.containerController.eventHandler = stateMachine
        appcues.analyticsPublisher.onPublish = { update in updates.append(update) }

        let observer = ExperienceStateMachine.AnalyticsObserver(container: appcues.container)
        stateMachine.addObserver(observer)

        // Act
        (package.containerController as! Mocks.ContainerViewController).mockIsBeingDismissed = true
        package.containerController.viewWillDisappear(false)
        package.containerController.viewDidDisappear(false)

        // Assert
        waitForExpectations(timeout: 1)
        let lastUpdate = try XCTUnwrap(updates.last)
        // confirm that dismiss on last step triggers experience_dismissed analytics, not experience_completed
        XCTAssertEqual(lastUpdate.type, .event(name: "appcues:v2:experience_dismissed", interactive: false))
    }

    func test_whenEndExperience_andMarkComplete_executesActions() throws {
        // Arrange
        appcues.sessionID = UUID() // needed to pass a check to show the next experience

        let dismissExpectation = expectation(description: "Experience dismissed")
        let nextContentLoadedExpectation = expectation(description: "Next content ID requested")
        let experience = ExperienceData.mock
        let package: ExperiencePackage = experience.package(dismissExpectation: dismissExpectation)

        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 1), package, isFirst: false)
        let action: Action = .endExperience(markComplete: true)
        let stateMachine = givenState(is: initialState)

        appcues.experienceLoader.onLoad = { contentID, published, trigger, completion in
            XCTAssertEqual(contentID, ExperienceData.mock.nextContentID)
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
        let experience = ExperienceData.mock
        let package: ExperiencePackage = experience.package(dismissExpectation: dismissExpectation)

        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 1), package, isFirst: false)
        let action: Action = .endExperience(markComplete: false)
        let stateMachine = givenState(is: initialState)

        appcues.experienceLoader.onLoad = { contentID, published, trigger, completion in
            XCTFail("no next content should be shown")
        }

        // Act
        try stateMachine.transition(action)

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertEqual(stateMachine.state, .idling)
    }

    func test_stateIsRenderingStep_whenStartStep_executesNavigationActionsBeforeTransition() throws {
        // when the next step group has actions on "navigate" trigger, they are executed sequentially
        // before presenting the next group container

        // Arrange
        var executionSequence: [String] = []
        let action1ExecutionExpectation = expectation(description: "Action 1 executed")
        let action2ExecutionExpectation = expectation(description: "Action 2 executed")
        let presentExpectation = expectation(description: "Experience presented")
        let action1 = Experience.Action(
            trigger: "navigate",
            type: TestAction.type,
            config: TestAction.Config(onExecute: DecodableExecuteBlock {
                executionSequence.append("action1")
                action1ExecutionExpectation.fulfill()
            }))
        let action2 = Experience.Action(
            trigger: "navigate",
            type: TestAction.type,
            config: TestAction.Config(onExecute: DecodableExecuteBlock {
                executionSequence.append("action2")
                action2ExecutionExpectation.fulfill()
            }))
        let actionRegistry = appcues.container.resolve(ActionRegistry.self)
        actionRegistry.register(action: TestAction.self)
        let experience = ExperienceData.mockWithStepActions(actions: [action1, action2], trigger: .qualification(reason: nil))
        let package: ExperiencePackage = experience.package(onPresent: {
            executionSequence.append("present")
            presentExpectation.fulfill()
        }, onDismiss: {})
        appcues.traitComposer.onPackage = { _, _ in
            return package
        }

        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 0), package, isFirst: true)
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
        XCTAssertEqual(["action1", "action2", "present"], executionSequence)
    }

    func test_stateIsIdling_whenStartExperience_doesNotExecutesNavigationActionsOnQualifiedExperience() throws {
        // when the first step group has actions on "navigate" trigger, and the flow is triggered from
        // qualification in a certain context - the pre-step actions should not execute before the flow starts

        // Arrange
        var executionSequence: [String] = []
        let action1ExecutionExpectation = expectation(description: "Action 1 executed")
        action1ExecutionExpectation.isInverted = true
        let action2ExecutionExpectation = expectation(description: "Action 2 executed")
        action2ExecutionExpectation.isInverted = true
        let presentExpectation = expectation(description: "Experience presented")
        let action1 = Experience.Action(
            trigger: "navigate",
            type: TestAction.type,
            config: TestAction.Config(onExecute: DecodableExecuteBlock {
                executionSequence.append("action1")
                action1ExecutionExpectation.fulfill()
            }))
        let action2 = Experience.Action(
            trigger: "navigate",
            type: TestAction.type,
            config: TestAction.Config(onExecute: DecodableExecuteBlock {
                executionSequence.append("action2")
                action2ExecutionExpectation.fulfill()
            }))
        let actionRegistry = appcues.container.resolve(ActionRegistry.self)
        actionRegistry.register(action: TestAction.self)
        let experience = ExperienceData.mockWithStepActions(actions: [action1, action2], trigger: .qualification(reason: nil))
        let package: ExperiencePackage = experience.package(onPresent: {
            executionSequence.append("present")
            presentExpectation.fulfill()
        }, onDismiss: {})
        appcues.traitComposer.onPackage = { _, _ in
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
        XCTAssertEqual(["present"], executionSequence)
    }

    func test_stateIsIdling_whenStartExperience_executesNavigationActionsOnNonQualifiedExperience() throws {
        // when the first step group has actions on "navigate" trigger, and the flow is triggered from
        // something other than qualification - the pre-step actions should execute before the flow starts

        // Arrange
        var executionSequence: [String] = []
        let action1ExecutionExpectation = expectation(description: "Action 1 executed")
        let action2ExecutionExpectation = expectation(description: "Action 2 executed")
        let presentExpectation = expectation(description: "Experience presented")
        let action1 = Experience.Action(
            trigger: "navigate",
            type: TestAction.type,
            config: TestAction.Config(onExecute: DecodableExecuteBlock {
                executionSequence.append("action1")
                action1ExecutionExpectation.fulfill()
            }))
        let action2 = Experience.Action(
            trigger: "navigate",
            type: TestAction.type,
            config: TestAction.Config(onExecute: DecodableExecuteBlock {
                executionSequence.append("action2")
                action2ExecutionExpectation.fulfill()
            }))
        let actionRegistry = appcues.container.resolve(ActionRegistry.self)
        actionRegistry.register(action: TestAction.self)
        let experience = ExperienceData.mockWithStepActions(actions: [action1, action2], trigger: .deepLink)
        let package: ExperiencePackage = experience.package(onPresent: {
            executionSequence.append("present")
            presentExpectation.fulfill()
        }, onDismiss: {})
        appcues.traitComposer.onPackage = { _, _ in
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
        XCTAssertEqual(["action1", "action2", "present"], executionSequence)
    }

    // MARK: Error Transitions

    func test_stateIsIdling_whenStartExperienceWithNoSteps_noTransition() throws {
        // Arrange
        let experience = Experience(id: UUID(), name: "Empty experience", type: "mobile", publishedAt: 1632142800000, context: nil, traits: [], steps: [], redirectURL: nil, nextContentID: nil, renderContext: .modal)
        let initialState: State = .idling
        let action: Action = .startExperience(ExperienceData(experience, trigger: .showCall))
        let stateMachine = givenState(is: initialState)

        // Act
        try stateMachine.transition(action)

        // Assert
        XCTAssertEqual(stateMachine.state, initialState)
    }

    func test_stateIsIdling_whenStartFailedExperience_noTransition() throws {
        // Arrange
        let failedExperience = FailedExperience(id: UUID(), name: "Invalid experience", type: "mobile", publishedAt: 1632142800000, context: nil, error: "could not decode")
        let initialState: State = .idling
        let experienceData = ExperienceData(failedExperience.skeletonExperience, trigger: .showCall, error: failedExperience.error)
        let action: Action = .startExperience(experienceData)
        let stateMachine = givenState(is: initialState)

        // Act
        try stateMachine.transition(action)

        // Assert
        XCTAssertEqual(stateMachine.state, initialState)
    }

    func test_stateIsIdling_whenStartExperienceDelegateBlocks_noTransition() throws {
        // Arrange
        let experience = ExperienceData.mock
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
        let experience = ExperienceData.mock
        appcues.traitComposer.onPackage = { _, stepIndex in
            throw AppcuesTraitError(description: "Presenting capability trait required")
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
        let experience = ExperienceData.mock
        appcues.traitComposer.onPackage = { _, stepIndex in
            throw AppcuesTraitError(description: "Presenting capability trait required")
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
        let experience = ExperienceData.mock
        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 1), experience.package(), isFirst: false)
        let action: Action = .startExperience(ExperienceData.mock)
        let stateMachine = givenState(is: initialState)

        // Act
        try stateMachine.transition(action)

        // Assert
        XCTAssertEqual(stateMachine.state, initialState)
    }

    func test_stateIsRenderingStep_whenStartStepInvalid_noTransition() throws {
        // Arrange
        let experience = ExperienceData.mock
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
        let experience = ExperienceData.mock
        let initialState: State = .endingStep(experience, Experience.StepIndex(group: 0, item: 1), experience.package(), markComplete: true)
        let action: Action = .startStep(StepReference.index(1000))
        let stateMachine = givenState(is: initialState)

        // Act
        try stateMachine.transition(action)

        // Assert
        XCTAssertEqual(stateMachine.state, initialState)
    }
    func test_stateIsRenderingStep_whenReportNonFatalError_noTransition() throws {
        // Arrange
        let experience = ExperienceData.mock
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
        let experience = ExperienceData.mock
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
        let experience = ExperienceData.mock
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
        let experience = ExperienceData.mock
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

@available(iOS 13.0, *)
private extension ExperienceStateMachineTests {
    class TestAction: AppcuesExperienceAction {
        struct Config: Decodable {
            let onExecute: DecodableExecuteBlock?
        }
        static let type = "@test/action"

        var onExecute: (() -> Void)?

        required init?(configuration: AppcuesExperiencePluginConfiguration) {
            let config = configuration.decode(Config.self)
            onExecute = config?.onExecute?.block
        }

        func execute(completion: @escaping () -> Void) {
            onExecute?()
            completion()
        }
    }

    // A simple closure isn't Decodable for use in TestAction, so fake it with this wrapper
    // that stores the expectation in a static var to "decode" from
    struct DecodableExecuteBlock: Decodable {
        private static var blockStore: [UUID: () -> Void] = [:]

        let block: () -> Void
        private let blockID: UUID

        init(block: @escaping () -> Void) {
            self.block = block
            self.blockID = UUID()
            Self.blockStore[blockID] = block
        }

        enum CodingKeys: CodingKey {
            case blockID
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            self.blockID = try container.decode(UUID.self, forKey: .blockID)
            if let block = Self.blockStore[blockID] {
                self.block = block
            } else {
                throw DecodingError.valueNotFound(XCTestExpectation.self, .init(codingPath: [], debugDescription: "cant find block"))
            }
        }
    }
}
