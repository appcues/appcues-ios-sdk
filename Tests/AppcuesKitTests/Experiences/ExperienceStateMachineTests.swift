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
    typealias SideEffect = ExperienceStateMachine.SideEffect

    var appcues: MockAppcues!

    override func setUpWithError() throws {
        appcues = MockAppcues()
    }

    func testInitialState() throws {
        // Arrange
        let stateMachine = ExperienceStateMachine(container: appcues.container)

        // Assert
        XCTAssertEqual(stateMachine.state, .idling)
    }

    // MARK: Standard Transitions

    func test_stateIsIdling_whenStartExperience_transitionsToRenderingStep() async throws {
        // Arrange
        let presentExpectation = expectation(description: "Experience presented")
        let experience = ExperienceData.mock
        let package: ExperiencePackage = await experience.package(presentExpectation: presentExpectation)
        await appcues.traitComposer.setPackage { _, stepIndex in
            XCTAssertEqual(stepIndex, Experience.StepIndex(group: 0, item: 0))
            return package
        }

        let initialState: State = .idling
        let action: Action = .startExperience(experience)
        let stateMachine = await givenState(is: initialState)

        // Act
        try await stateMachine.transition(action)

        // Assert
        await fulfillment(of: [presentExpectation], timeout: 1)
        XCTAssertEqual(
            stateMachine.state,
            .renderingStep(experience, Experience.StepIndex(group: 0, item: 0), package, isFirst: true)
        )
        XCTAssertTrue(package.containerController.eventHandler === stateMachine)
    }

    func test_stateIsRenderingStep_whenStartStep_transitionsToRenderingStepInSameGroup() async throws {
        // the @appcues/continue action would do this

        // Arrange
        let presentExpectation = expectation(description: "Experience presented")
        presentExpectation.isInverted = true
        let experience = ExperienceData.mock
        let package: ExperiencePackage = await experience.package(presentExpectation: presentExpectation)

        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 0), package, isFirst: false)
        let action: Action = .startStep(StepReference.offset(1))
        let stateMachine = await givenState(is: initialState)

        // This would be set in the initial presentation of the group container, but we've skipped over that by setting
        // the initial state of the machine. This is relied upon so the containerController can notify the state machine
        // of the completed change. This being properly set is tested in
        // test_stateIsIdling_whenStartExperience_transitionsToRenderingStep
        package.containerController.eventHandler = stateMachine
        package.pageMonitor.addObserver { newIndex, oldIndex in
            stateMachine.containerNavigated(from: oldIndex, to: newIndex)
        }

        // Act
        try await stateMachine.transition(action)

        // Assert
        await fulfillment(of: [presentExpectation], timeout: 1)
        XCTAssertEqual(
            stateMachine.state,
            .renderingStep(experience, Experience.StepIndex(group: 0, item: 1), package, isFirst: false)
        )
    }

    func test_stateIsRenderingStep_whenStartStep_transitionsToRenderingStepInNewGroup() async throws {
        // the @appcues/continue action would do this

        // Arrange
        let presentExpectation = expectation(description: "Experience presented")
        let experience = ExperienceData.mock
        let package: ExperiencePackage = await experience.package(presentExpectation: presentExpectation)
        await appcues.traitComposer.setPackage { _, stepIndex in
            XCTAssertEqual(stepIndex, Experience.StepIndex(group: 1, item: 0))
            return package
        }

        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 2), package, isFirst: false)
        let action: Action = .startStep(StepReference.offset(1))
        let stateMachine = await givenState(is: initialState)

        // Act
        try await stateMachine.transition(action)

        // Assert
        await fulfillment(of: [presentExpectation], timeout: 1)
        XCTAssertEqual(
            stateMachine.state,
            .renderingStep(experience, Experience.StepIndex(group: 1, item: 0), package, isFirst: false)
        )
    }

    func test_stateIsRenderingStep_whenStartStepPastEnd_transitionsToIdling() async throws {
        // the @appcues/continue action would do this

        // Arrange
        let dismissExpectation = expectation(description: "Experience dismissed")
        let experience = ExperienceData.mock
        let package: ExperiencePackage = await experience.package(dismissExpectation: dismissExpectation)

        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 1, item: 0), package, isFirst: false)
        let action: Action = .startStep(StepReference.offset(1))
        let stateMachine = await givenState(is: initialState)

        // Act
        try await stateMachine.transition(action)

        // Assert
        await fulfillment(of: [dismissExpectation], timeout: 1)
        XCTAssertEqual(stateMachine.state, .idling)
    }

    func test_stateIsRenderingStep_whenEndExperience_transitionsToIdling() async throws {
        // the @appcues/close action would do this

        // Arrange
        let dismissExpectation = expectation(description: "Experience dismissed")
        let experience = ExperienceData.mock
        let package: ExperiencePackage = await experience.package(dismissExpectation: dismissExpectation)

        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 1), package, isFirst: false)
        let action: Action = .endExperience(markComplete: false)
        let stateMachine = await givenState(is: initialState)

        // Act
        try await stateMachine.transition(action)

        // Assert
        await fulfillment(of: [dismissExpectation], timeout: 1)
        XCTAssertEqual(stateMachine.state, .idling)
    }

    func test_stateIsRenderingStep_onViewControllerDismissed_transitionsToIdling() async throws {
        // the @appcues/skippable trait would do this

        // Arrange
        let dismissExpectation = expectation(description: "Experience dismissed")
        let experience = ExperienceData.mock
        let package: ExperiencePackage = await experience.package(dismissExpectation: dismissExpectation)

        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 1), package, isFirst: false)
        let stateMachine = await givenState(is: initialState)
        package.containerController.eventHandler = stateMachine

        // Act
        Task { @MainActor in
            (package.containerController as! Mocks.ContainerViewController).mockIsBeingDismissed = true
            package.containerController.viewWillDisappear(false)
            package.containerController.viewDidDisappear(false)
        }

        // Assert
        await fulfillment(of: [dismissExpectation], timeout: 1)
        XCTAssertEqual(stateMachine.state, .idling)
    }

    func test_stateIsRenderingStep_onViewControllerDismissed_doesNotMarkComplete() async throws {
        // the @appcues/skippable trait would do this

        // Arrange
        var updates: [TrackingUpdate] = []
        let dismissExpectation = expectation(description: "Experience dismissed")
        let experience = ExperienceData.mock
        let package: ExperiencePackage = await experience.package(dismissExpectation: dismissExpectation)

        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 1, item: 0), package, isFirst: true)
        let stateMachine = await givenState(is: initialState)
        package.containerController.eventHandler = stateMachine
        appcues.analyticsPublisher.onPublish = { update in updates.append(update) }

        let observer = ExperienceStateMachine.AnalyticsObserver(container: appcues.container)
        stateMachine.addObserver(observer)

        // Act
        Task { @MainActor in
            (package.containerController as! Mocks.ContainerViewController).mockIsBeingDismissed = true
            package.containerController.viewWillDisappear(false)
            package.containerController.viewDidDisappear(false)
        }

        // Assert
        await fulfillment(of: [dismissExpectation], timeout: 1)
        let lastUpdate = try XCTUnwrap(updates.last)
        // confirm that dismiss on last step triggers experience_dismissed analytics, not experience_completed
        XCTAssertEqual(lastUpdate.type, .event(name: "appcues:v2:experience_dismissed", interactive: false))
    }

    func test_whenEndExperience_andMarkComplete_executesActions() async throws {
        // Arrange
        appcues.sessionID = UUID() // needed to pass a check to show the next experience

        let dismissExpectation = expectation(description: "Experience dismissed")
        let nextContentLoadedExpectation = expectation(description: "Next content ID requested")
        let experience = ExperienceData.mock
        let package: ExperiencePackage = await experience.package(dismissExpectation: dismissExpectation)

        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 1), package, isFirst: false)
        let action: Action = .endExperience(markComplete: true)
        let stateMachine = await givenState(is: initialState)

        appcues.contentLoader.onLoad = { contentID, published, trigger in
            XCTAssertEqual(contentID, ExperienceData.mock.nextContentID)
            XCTAssertTrue(published)
            nextContentLoadedExpectation.fulfill()
        }

        // Act
        try await stateMachine.transition(action)

        // Assert
        await fulfillment(of: [dismissExpectation, nextContentLoadedExpectation], timeout: 1, enforceOrder: true)
        XCTAssertEqual(stateMachine.state, .idling)
    }

    func test_whenEndExperience_andNoMarkComplete_doesNotExecuteActions() async throws {
        // Arrange
        appcues.sessionID = UUID() // needed to pass a check to show the next experience

        let dismissExpectation = expectation(description: "Experience dismissed")
        let nextContentLoadedExpectation = expectation(description: "Next content ID requested")
        nextContentLoadedExpectation.isInverted = true
        let experience = ExperienceData.mock
        let package: ExperiencePackage = await experience.package(dismissExpectation: dismissExpectation)

        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 1), package, isFirst: false)
        let action: Action = .endExperience(markComplete: false)
        let stateMachine = await givenState(is: initialState)

        appcues.contentLoader.onLoad = { contentID, published, trigger in
            XCTFail("no next content should be shown")
        }

        // Act
        try await stateMachine.transition(action)

        // Assert
        await fulfillment(of: [dismissExpectation, nextContentLoadedExpectation], timeout: 1, enforceOrder: true)
        XCTAssertEqual(stateMachine.state, .idling)
    }

    func test_stateIsRenderingStep_whenStartStep_executesNavigationActionsBeforeTransition() async throws {
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
        let package: ExperiencePackage = await experience.package(onPresent: {
            executionSequence.append("present")
            presentExpectation.fulfill()
        }, onDismiss: {})
        await appcues.traitComposer.setPackage { _, _ in
            return package
        }

        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 0), package, isFirst: true)
        let action: Action = .startStep(StepReference.offset(1))
        let stateMachine = await givenState(is: initialState)

        // Act
        try await stateMachine.transition(action)

        // Assert
        await fulfillment(of: [action1ExecutionExpectation, action2ExecutionExpectation, presentExpectation], timeout: 1, enforceOrder: true)
        XCTAssertEqual(
            stateMachine.state,
            .renderingStep(experience, Experience.StepIndex(group: 1, item: 0), package, isFirst: false)
        )
        XCTAssertEqual(["action1", "action2", "present"], executionSequence)
    }

    func test_stateIsIdling_whenStartExperience_doesNotExecutesNavigationActionsOnQualifiedExperience() async throws {
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
        let package: ExperiencePackage = await experience.package(onPresent: {
            executionSequence.append("present")
            presentExpectation.fulfill()
        }, onDismiss: {})
        await appcues.traitComposer.setPackage { _, _ in
            return package
        }

        let initialState: State = .idling
        let action: Action = .startExperience(experience)
        let stateMachine = await givenState(is: initialState)

        // Act
        try await stateMachine.transition(action)

        // Assert
        await fulfillment(of: [action1ExecutionExpectation, action2ExecutionExpectation, presentExpectation], timeout: 1, enforceOrder: true)
        XCTAssertEqual(
            stateMachine.state,
            .renderingStep(experience, Experience.StepIndex(group: 0, item: 0), package, isFirst: true)
        )
        XCTAssertEqual(["present"], executionSequence)
    }

    func test_stateIsIdling_whenStartExperience_executesNavigationActionsOnNonQualifiedExperience() async throws {
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
        let package: ExperiencePackage = await experience.package(onPresent: {
            executionSequence.append("present")
            presentExpectation.fulfill()
        }, onDismiss: {})
        await appcues.traitComposer.setPackage { _, _ in
            return package
        }

        let initialState: State = .idling
        let action: Action = .startExperience(experience)
        let stateMachine = await givenState(is: initialState)

        // Act
        try await stateMachine.transition(action)

        // Assert
        await fulfillment(of: [action1ExecutionExpectation, action2ExecutionExpectation, presentExpectation], timeout: 1, enforceOrder: true)
        XCTAssertEqual(
            stateMachine.state,
            .renderingStep(experience, Experience.StepIndex(group: 0, item: 0), package, isFirst: true)
        )
        XCTAssertEqual(["action1", "action2", "present"], executionSequence)
    }

    func test_stateIsFailing_whenRetry_transitionsToRestoreStateAndRetryEffect() async throws {
        let presentExpectation = expectation(description: "Experience presented")
        let experience = ExperienceData.mock
        let package: ExperiencePackage = await experience.package(presentExpectation: presentExpectation)
        let originalState: State = .beginningStep(experience, .initial, package, isFirst: true)
        let retryEffect: SideEffect = .retryPresentation(experience, .initial, package)
        let initialState: State = .failing(targetState: originalState, retryEffect: retryEffect)
        let stateMachine = await givenState(is: initialState)
        let listingObserver = ListingObserver()
        stateMachine.addObserver(listingObserver)
        let action: Action = .retry

        // Act
        try await stateMachine.transition(action)

        // Assert
        // the retry should transition back to the original state (.beginningStep),
        // call the retry effect to present, and then transition to renderingStep
        await fulfillment(of: [presentExpectation], timeout: 1)
        XCTAssertEqual(
            listingObserver.results,
            [
                .success(originalState),
                .success(.renderingStep(experience, .initial, package, isFirst: true))
            ]
        )
    }

    func test_stateIsFailing_whenEndExperience_transitionsToIdling() async throws {
        let presentExpectation = expectation(description: "Experience presented")
        presentExpectation.isInverted = true
        let experience = ExperienceData.mock
        let package: ExperiencePackage = await experience.package()
        let originalState: State = .beginningStep(experience, .initial, package, isFirst: true)
        let retryEffect: SideEffect = .retryPresentation(experience, .initial, package)
        let initialState: State = .failing(targetState: originalState, retryEffect: retryEffect)
        let stateMachine = await givenState(is: initialState)
        let listingObserver = ListingObserver()
        stateMachine.addObserver(listingObserver)
        let action: Action = .endExperience(markComplete: false)

        // Act
        try await stateMachine.transition(action)

        // Assert
        // the endExperience action should move straight to .idling, concluding the previous failed attempt.
        // and no presentation effect should be re-attempted
        await fulfillment(of: [presentExpectation], timeout: 1)
        XCTAssertEqual(listingObserver.results, [.success(.idling)])
    }

    func test_stateIsFailing_whenStartExperience_transitionsToIdlingThenStartsNewExperience() async throws {
        let failedPresentExpectation = expectation(description: "Failed experience presented")
        failedPresentExpectation.isInverted = true
        let failedExperience = ExperienceData.mock
        let failedPackage: ExperiencePackage = await failedExperience.package(presentExpectation: failedPresentExpectation)
        let failedStepIndex = Experience.StepIndex(group: 0, item: 1)
        let initialState: State = .failing(
            targetState: .beginningStep(failedExperience, failedStepIndex, failedPackage, isFirst: true),
            retryEffect: .retryPresentation(failedExperience, failedStepIndex, failedPackage)
        )

        let presentExpectation = expectation(description: "Experience presented")
        let experience = ExperienceData.mock
        let package: ExperiencePackage = await experience.package(presentExpectation: presentExpectation)
        await appcues.traitComposer.setPackage { _, stepIndex in
            XCTAssertEqual(stepIndex, .initial)
            return package
        }

        let action: Action = .startExperience(experience)
        let stateMachine = await givenState(is: initialState)
        let listingObserver = ListingObserver()
        stateMachine.addObserver(listingObserver)

        // Act
        try await stateMachine.transition(action)

        // Assert
        // the start experience should move the existing failed state back to idling, then start the new experience
        await fulfillment(of: [failedPresentExpectation, presentExpectation], timeout: 1)
        XCTAssertEqual(
            listingObserver.results,
            [
                .success(.idling),
                .success(.beginningExperience(experience)),
                .success(.beginningStep(experience, .initial, package, isFirst: true)),
                .success(.renderingStep(experience, .initial, package, isFirst: true))
            ]
        )
    }

    // MARK: Error Transitions

    func test_stateIsIdling_whenStartExperienceWithNoSteps_noTransition() async throws {
        // Arrange
        let experience = Experience(id: UUID(), name: "Empty experience", type: "mobile", publishedAt: 1632142800000, context: nil, traits: [], steps: [], redirectURL: nil, nextContentID: nil, renderContext: .modal)
        let initialState: State = .idling
        let action: Action = .startExperience(ExperienceData(experience, trigger: .showCall))
        let stateMachine = await givenState(is: initialState)

        // Act
        await XCTAssertThrowsAsyncError(try await stateMachine.transition(action)) {
            XCTAssertEqual(($0 as? ExperienceStateMachine.ExperienceError)?.description, "Experience has 0 steps")
        }

        // Assert
        XCTAssertEqual(stateMachine.state, initialState)
    }

    func test_stateIsIdling_whenStartFailedExperience_noTransition() async throws {
        // Arrange
        let failedExperience = FailedExperience(id: UUID(), name: "Invalid experience", type: "mobile", publishedAt: 1632142800000, context: nil, error: "could not decode")
        let initialState: State = .idling
        let experienceData = ExperienceData(failedExperience.skeletonExperience, trigger: .showCall, error: failedExperience.error)
        let action: Action = .startExperience(experienceData)
        let stateMachine = await givenState(is: initialState)

        // Act
        await XCTAssertThrowsAsyncError(try await stateMachine.transition(action)) {
            XCTAssertEqual(($0 as? ExperienceStateMachine.ExperienceError)?.description, "could not decode")
        }

        // Assert
        XCTAssertEqual(stateMachine.state, initialState)
    }

    func test_stateIsIdling_whenStartExperienceDelegateBlocks_noTransition() async throws {
        // Arrange
        let experience = ExperienceData.mock
        await appcues.traitComposer.setPackage { _, _ in experience.package() }

        let initialState: State = .idling
        let action: Action = .startExperience(experience)
        let stateMachine = await givenState(is: initialState)

        let mockDelegate = MockAppcuesExperienceDelegate(canDisplay: false)
        stateMachine.clientAppcuesDelegate = mockDelegate

        // Act
        try await stateMachine.transition(action)

        // Assert
        XCTAssertEqual(stateMachine.state, initialState)
    }

    func test_stateIsIdling_whenStartExperiencePackageFails_transitionsToIdling() async throws {
        // Arrange
        let experience = ExperienceData.mock
        await appcues.traitComposer.setPackage { _, stepIndex in
            throw AppcuesTraitError(description: "Presenting capability trait required")
        }

        let initialState: State = .idling
        let action: Action = .startExperience(experience)
        let stateMachine = await givenState(is: initialState)

        // Act
        await XCTAssertThrowsAsyncError(try await stateMachine.transition(action)) {
            XCTAssertEqual(($0 as? ExperienceStateMachine.ExperienceError)?.description, "Presenting capability trait required")
        }

        // Assert
        XCTAssertEqual(
            stateMachine.state,
            .idling
        )
    }

    func test_stateIsIdling_whenStartStepFails_transitionsToIdling() async throws {
        // Arrange
        let presentThrowExpectation = expectation(description: "Experience presented attempt")
        let experience = ExperienceData.mock
        await appcues.traitComposer.setPackage { _, stepIndex in
            experience.package(
                onPresent: {
                    presentThrowExpectation.fulfill()
                    throw AppcuesTraitError(description: "present fail", recoverable: false)
                },
                onDismiss: { /* nothing */ }
            )
        }

        let initialState: State = .idling
        let action: Action = .startExperience(experience)
        let stateMachine = await givenState(is: initialState)

        // Act
        try await stateMachine.transition(action)

        // Assert
        await fulfillment(of: [presentThrowExpectation], timeout: 1)
        XCTAssertEqual(
            stateMachine.state,
            .idling
        )
    }

    // This is the error case where something like a carousel swipe or paging dot interaction trigger a step change
    func test_stateIsRenderingStep_whenPageChangeFails_transitionsToIdling() async throws {
        // Arrange
        let presentExpectation = expectation(description: "Experience presented")
        let dismissExpectation = expectation(description: "Experience dismissed")
        let experience = ExperienceData.mock
        let package: ExperiencePackage = await experience.package(
            onPresent: { presentExpectation.fulfill() },
            onDismiss: { dismissExpectation.fulfill() },
            stepDecorator: { _, prev in
                // succeed the first time when presenting, then fail on the step change
                if prev != nil {
                    throw AppcuesTraitError(description: "decorate fail", recoverable: false)
                }
            }
        )
        await appcues.traitComposer.setPackage { _, stepIndex in
            return package
        }

        let initialState: State = .idling
        let action: Action = .startExperience(experience)
        let stateMachine = await givenState(is: initialState)

        // Act
        // Need to do a proper transition instead of initialState so the pageMonitor observer is actually added
        try await stateMachine.transition(action)
        await fulfillment(of: [presentExpectation], timeout: 1)

        package.pageMonitor.set(currentPage: 1)

        // Assert
        await fulfillment(of: [dismissExpectation], timeout: 1)
        XCTAssertEqual(
            stateMachine.state,
            .idling
        )
    }

    func test_stateIsRenderingStep_whenStartStepPackageFails_transitionsToIdling() async throws {
        // Arrange
        let experience = ExperienceData.mock
        await appcues.traitComposer.setPackage { _, stepIndex in
            throw AppcuesTraitError(description: "Presenting capability trait required")
        }

        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 0), await experience.package(), isFirst: false)
        // Step ID in a different container
        let targetID = try XCTUnwrap(UUID(uuidString: "03652bd5-f0cb-44f0-9274-e95b4441d857"))
        let action: Action = .startStep(.stepID(targetID))
        let stateMachine = await givenState(is: initialState)

        // Act
        try await stateMachine.transition(action)

        // Assert
        XCTAssertEqual(
            stateMachine.state,
            .idling
        )
    }

    func test_stateIsRenderingStep_whenStartExperience_noTransition() async throws {
        // Arrange
        let experience = ExperienceData.mock
        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 1), await experience.package(), isFirst: false)
        let action: Action = .startExperience(ExperienceData.mock)
        let stateMachine = await givenState(is: initialState)

        // Act
        await XCTAssertThrowsAsyncError(try await stateMachine.transition(action)) {
            XCTAssertEqual(($0 as? ExperienceStateMachine.ExperienceError)?.description, "experience already active")
        }

        // Assert
        XCTAssertEqual(stateMachine.state, initialState)
    }

    func test_stateIsRenderingStep_whenStartStepInvalid_noTransition() async throws {
        // Arrange
        let experience = ExperienceData.mock
        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 1), await experience.package(), isFirst: false)
        let action: Action = .startStep(StepReference.index(1000))
        let stateMachine = await givenState(is: initialState)

        // Act
        await XCTAssertThrowsAsyncError(try await stateMachine.transition(action)) {
            XCTAssertEqual(($0 as? ExperienceStateMachine.ExperienceError)?.description, "Step at index(1000) does not exist")
        }

        // Assert
        XCTAssertEqual(stateMachine.state, initialState)
    }

    func test_stateIsEndingStep_whenStartStepInvalid_noTransition() async throws {
        // Note: in actual usage, the invalid StepReference should be caught before transitioning to .endingStep
        // (see test_stateIsRenderingStep_whenStartStepInvalid_noTransition above)

        // Arrange
        let experience = ExperienceData.mock
        let initialState: State = .endingStep(experience, Experience.StepIndex(group: 0, item: 1), await experience.package(), markComplete: true)
        let action: Action = .startStep(StepReference.index(1000))
        let stateMachine = await givenState(is: initialState)

        // Act
        await XCTAssertThrowsAsyncError(try await stateMachine.transition(action)) {
            XCTAssertEqual(($0 as? ExperienceStateMachine.ExperienceError)?.description, "Step at index(1000) does not exist")
        }

        // Assert
        XCTAssertEqual(stateMachine.state, initialState)
    }

    func test_stateIsRenderingStep_whenReportErrorWithRetryEffect_transitionsToFailing() async throws {
        // Arrange
        let experience = ExperienceData.mock
        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 0), await experience.package(), isFirst: false)
        let effect: ExperienceStateMachine.SideEffect = .continuation(.reset)
        let action: Action = .reportError(
            error: ExperienceStateMachine.ExperienceError.experience(experience, "error"),
            retryEffect: effect
        )
        let stateMachine = await givenState(is: initialState)

        // Act
        await XCTAssertThrowsAsyncError(try await stateMachine.transition(action)) {
            XCTAssertEqual(($0 as? ExperienceStateMachine.ExperienceError)?.description, "error")
        }

        // Assert
        XCTAssertEqual(stateMachine.state, .failing(targetState: initialState, retryEffect: effect))
    }

    func test_stateIsRenderingStep_whenReportErrorWithoutRetryEffect_transitionsToIdling() async throws {
        // Arrange
        let experience = ExperienceData.mock
        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 0), await experience.package(), isFirst: false)
        let action: Action = .reportError(
            error: ExperienceStateMachine.ExperienceError.experience(experience, "error"),
            retryEffect: nil
        )
        let stateMachine = await givenState(is: initialState)

        // Act
        await XCTAssertThrowsAsyncError(try await stateMachine.transition(action)) {
            XCTAssertEqual(($0 as? ExperienceStateMachine.ExperienceError)?.description, "error")
        }

        // Assert
        XCTAssertEqual(stateMachine.state, .idling)
        XCTAssertEqual(stateMachine.stateObservers.count, 0, "observer is removed on fatal error and return to idling")
    }

    func testExperienceErrorNotifiesObserver() async throws {
        // Arrange
        let experience = ExperienceData.mock
        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 0), await experience.package(), isFirst: false)
        let effect: ExperienceStateMachine.SideEffect = .continuation(.reset)
        let action: Action = .reportError(
            error: ExperienceStateMachine.ExperienceError.experience(experience, "error"),
            retryEffect: effect
        )
        let stateMachine = await givenState(is: initialState)
        let listingObserver = ListingObserver()
        stateMachine.addObserver(listingObserver)

        // Act
        await XCTAssertThrowsAsyncError(try await stateMachine.transition(action)) {
            XCTAssertEqual(($0 as? ExperienceStateMachine.ExperienceError)?.description, "error")
        }

        // Assert
        XCTAssertEqual(
            listingObserver.results,
            [
                .success(.failing(targetState: initialState, retryEffect: effect)),
                .failure(.experience(experience, "error"))
            ]
        )
    }

    func testFatalExperienceErrorNotifiesObserver() async throws {
        // Arrange
        let experience = ExperienceData.mock
        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 0), await experience.package(), isFirst: false)
        let action: Action = .reportError(
            error: ExperienceStateMachine.ExperienceError.experience(experience, "error"),
            retryEffect: nil
        )
        let stateMachine = await givenState(is: initialState)
        let listingObserver = ListingObserver()
        stateMachine.addObserver(listingObserver)

        // Act
        await XCTAssertThrowsAsyncError(try await stateMachine.transition(action)) {
            XCTAssertEqual(($0 as? ExperienceStateMachine.ExperienceError)?.description, "error")
        }

        // Assert
        XCTAssertEqual(
            listingObserver.results,
            [
                .success(.idling),
                .failure(.experience(experience, "error"))
            ]
        )
        XCTAssertEqual(stateMachine.stateObservers.count, 0, "observer is removed when reset to idling")
    }

    func test_stateIsRenderingStep_whenReset_noTransition() async throws {
        // Invalid action for given state

        // Arrange
        let experience = ExperienceData.mock
        let initialState: State = .renderingStep(experience, Experience.StepIndex(group: 0, item: 0), await experience.package(), isFirst: false)
        let action: Action = .reset
        let stateMachine = await givenState(is: initialState)

        // Act/Assert
        await XCTAssertThrowsAsyncError(try await stateMachine.transition(action)) {
            XCTAssertNotNil($0 as? ExperienceStateMachine.InvalidTransition)
        }
        XCTAssertEqual(stateMachine.state, initialState)
    }

    // MARK: - Helpers

    func givenState(is state: ExperienceStateMachine.State) async -> ExperienceStateMachine {
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
    func stateChanged(to result: StateResult) {
        results.append(result)
    }
}

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

        func execute() async {
            onExecute?()
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
