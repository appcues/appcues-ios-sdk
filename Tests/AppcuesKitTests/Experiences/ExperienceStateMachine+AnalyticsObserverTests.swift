//
//  ExperienceStateMachine+AnalyticsObserverTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-03-21.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

@available(iOS 13.0, *)
class ExperienceStateMachine_AnalyticsObserverTests: XCTestCase {

    var appcues: MockAppcues!
    private var analyticsSubscriber: Mocks.TestSubscriber!
    var observer: ExperienceStateMachine.AnalyticsObserver!

    override func setUpWithError() throws {
        appcues = MockAppcues()
        analyticsSubscriber = Mocks.TestSubscriber()
        appcues.register(subscriber: analyticsSubscriber)
        observer = ExperienceStateMachine.AnalyticsObserver(container: appcues.container)
    }

    override func tearDownWithError() throws {
        // Reset fixed UUID
        UUID.generator = UUID.init
    }

    func testEvaluateIdlingState() throws {
        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.idling))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(analyticsSubscriber.trackedUpdates, 0)
    }

    func testEvaluateBeginningExperienceState() throws {
        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.beginningExperience(Experience.mock)))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(analyticsSubscriber.trackedUpdates, 0)
    }

    func testEvaluateBeginningStepState() throws {
        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.beginningStep(Experience.mock, .initial, Experience.mock.package(), isFirst: true)))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(analyticsSubscriber.trackedUpdates, 0)
    }

    func testEvaluateRenderingFirstStepState() throws {
        // Precondition
        XCTAssertNil(appcues.storage.lastContentShownAt)

        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.renderingStep(Experience.mock, .initial, Experience.mock.package(), isFirst: true)))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(analyticsSubscriber.trackedUpdates, 2)
        let lastUpdate = try XCTUnwrap(analyticsSubscriber.lastUpdate)
        XCTAssertEqual(lastUpdate.type, .event(name: "appcues:v2:step_seen", interactive: false))
        [
            "experienceName": "Mock Experience: Group with 3 steps, Single step",
            "experienceId": "54b7ec71-cdaf-4697-affa-f3abd672b3cf",
            "version": 1632142800000,
            "experienceType": "mobile",
            "stepType": "modal",
            "stepId": "e03ae132-91b7-4cb0-9474-7d4a0e308a07",
            "stepIndex": "0,0"
        ].verifyPropertiesMatch(lastUpdate.properties)
        XCTAssertNotNil(appcues.storage.lastContentShownAt)

        XCTAssertEqual(
            try XCTUnwrap(LifecycleEvent.restructure(update: lastUpdate)),
            LifecycleEvent.EventProperties(
                type: .stepSeen,
                experienceID: UUID(uuidString: "54b7ec71-cdaf-4697-affa-f3abd672b3cf")!,
                experienceName: "Mock Experience: Group with 3 steps, Single step",
                stepID: UUID(uuidString: "e03ae132-91b7-4cb0-9474-7d4a0e308a07"),
                stepIndex: Experience.StepIndex(group: 0, item: 0)
            ),
            "can succesfully remap the property dict"
        )
    }

    func testEvaluateRenderingStepState() throws {
        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.renderingStep(Experience.mock, .initial, Experience.mock.package(), isFirst: false)))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(analyticsSubscriber.trackedUpdates, 1)
        let lastUpdate = try XCTUnwrap(analyticsSubscriber.lastUpdate)
        XCTAssertEqual(lastUpdate.type, .event(name: "appcues:v2:step_seen", interactive: false))
        [
            "experienceName": "Mock Experience: Group with 3 steps, Single step",
            "experienceId": "54b7ec71-cdaf-4697-affa-f3abd672b3cf",
            "version": 1632142800000,
            "experienceType": "mobile",
            "stepType": "modal",
            "stepId": "e03ae132-91b7-4cb0-9474-7d4a0e308a07",
            "stepIndex": "0,0"
        ].verifyPropertiesMatch(lastUpdate.properties)

        XCTAssertEqual(
            try XCTUnwrap(LifecycleEvent.restructure(update: lastUpdate)),
            LifecycleEvent.EventProperties(
                type: .stepSeen,
                experienceID: UUID(uuidString: "54b7ec71-cdaf-4697-affa-f3abd672b3cf")!,
                experienceName: "Mock Experience: Group with 3 steps, Single step",
                stepID: UUID(uuidString: "e03ae132-91b7-4cb0-9474-7d4a0e308a07"),
                stepIndex: Experience.StepIndex(group: 0, item: 0)
            ),
            "can succesfully remap the property dict"
        )
    }

    func testEvaluateEndingStepState() throws {
        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.endingStep(Experience.mock, .initial, Experience.mock.package())))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(analyticsSubscriber.trackedUpdates, 1)
        let lastUpdate = try XCTUnwrap(analyticsSubscriber.lastUpdate)
        XCTAssertEqual(lastUpdate.type, .event(name: "appcues:v2:step_completed", interactive: false))
        [
            "experienceName": "Mock Experience: Group with 3 steps, Single step",
            "experienceId": "54b7ec71-cdaf-4697-affa-f3abd672b3cf",
            "version": 1632142800000,
            "experienceType": "mobile",
            "stepType": "modal",
            "stepId": "e03ae132-91b7-4cb0-9474-7d4a0e308a07",
            "stepIndex": "0,0"
        ].verifyPropertiesMatch(lastUpdate.properties)

        XCTAssertEqual(
            try XCTUnwrap(LifecycleEvent.restructure(update: lastUpdate)),
            LifecycleEvent.EventProperties(
                type: .stepCompleted,
                experienceID: UUID(uuidString: "54b7ec71-cdaf-4697-affa-f3abd672b3cf")!,
                experienceName: "Mock Experience: Group with 3 steps, Single step",
                stepID: UUID(uuidString: "e03ae132-91b7-4cb0-9474-7d4a0e308a07"),
                stepIndex: Experience.StepIndex(group: 0, item: 0)
            ),
            "can succesfully remap the property dict"
        )
    }

    func testEvaluateEndingExperienceState() throws {
        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.endingExperience(Experience.mock, .initial, markComplete: false)))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(analyticsSubscriber.trackedUpdates, 1)
        let lastUpdate = try XCTUnwrap(analyticsSubscriber.lastUpdate)
        XCTAssertEqual(lastUpdate.type, .event(name: "appcues:v2:experience_dismissed", interactive: false))
        [
            "experienceName": "Mock Experience: Group with 3 steps, Single step",
            "experienceId": "54b7ec71-cdaf-4697-affa-f3abd672b3cf",
            "version": 1632142800000,
            "experienceType": "mobile",
            "stepType": "modal",
            "stepId": "e03ae132-91b7-4cb0-9474-7d4a0e308a07",
            "stepIndex": "0,0"
        ].verifyPropertiesMatch(lastUpdate.properties)

        XCTAssertEqual(
            try XCTUnwrap(LifecycleEvent.restructure(update: lastUpdate)),
            LifecycleEvent.EventProperties(
                type: .experienceDismissed,
                experienceID: UUID(uuidString: "54b7ec71-cdaf-4697-affa-f3abd672b3cf")!,
                experienceName: "Mock Experience: Group with 3 steps, Single step",
                stepID: UUID(uuidString: "e03ae132-91b7-4cb0-9474-7d4a0e308a07"),
                stepIndex: Experience.StepIndex(group: 0, item: 0)
            ),
            "can succesfully remap the property dict"
        )
    }

    func testEvaluateEndingExperienceStateMarkComplete() throws {
        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.endingExperience(Experience.mock, .initial, markComplete: true)))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(analyticsSubscriber.trackedUpdates, 1)
        let lastUpdate = try XCTUnwrap(analyticsSubscriber.lastUpdate)
        XCTAssertEqual(lastUpdate.type, .event(name: "appcues:v2:experience_completed", interactive: false))
        [
            "experienceName": "Mock Experience: Group with 3 steps, Single step",
            "experienceId": "54b7ec71-cdaf-4697-affa-f3abd672b3cf",
            "version": 1632142800000,
            "experienceType": "mobile"
        ].verifyPropertiesMatch(lastUpdate.properties)

        XCTAssertEqual(
            try XCTUnwrap(LifecycleEvent.restructure(update: lastUpdate)),
            LifecycleEvent.EventProperties(
                type: .experienceCompleted,
                experienceID: UUID(uuidString: "54b7ec71-cdaf-4697-affa-f3abd672b3cf")!,
                experienceName: "Mock Experience: Group with 3 steps, Single step"
            ),
            "can succesfully remap the property dict"
        )
    }

    func testEvaluateEndingExperienceLastStepState() throws {
        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.endingExperience(Experience.mock, Experience.StepIndex(group: 1, item: 0), markComplete: false)))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(analyticsSubscriber.trackedUpdates, 1)
        let lastUpdate = try XCTUnwrap(analyticsSubscriber.lastUpdate)
        XCTAssertEqual(lastUpdate.type, .event(name: "appcues:v2:experience_completed", interactive: false))
        [
            "experienceName": "Mock Experience: Group with 3 steps, Single step",
            "experienceId": "54b7ec71-cdaf-4697-affa-f3abd672b3cf",
            "version": 1632142800000,
            "experienceType": "mobile"
        ].verifyPropertiesMatch(lastUpdate.properties)

        XCTAssertEqual(
            try XCTUnwrap(LifecycleEvent.restructure(update: lastUpdate)),
            LifecycleEvent.EventProperties(
                type: .experienceCompleted,
                experienceID: UUID(uuidString: "54b7ec71-cdaf-4697-affa-f3abd672b3cf")!,
                experienceName: "Mock Experience: Group with 3 steps, Single step"
            ),
            "can succesfully remap the property dict"
        )
    }

    func testEvaluateExperienceError() throws {
        // Arrange
        UUID.generator = { UUID(uuidString: "A6D6E248-FAFF-4789-A03C-BD7F520C1181")! }

        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .failure(.experience(Experience.mock, "error")))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(analyticsSubscriber.trackedUpdates, 1)
        let lastUpdate = try XCTUnwrap(analyticsSubscriber.lastUpdate)
        XCTAssertEqual(lastUpdate.type, .event(name: "appcues:v2:experience_error", interactive: false))
        [
            "experienceName": "Mock Experience: Group with 3 steps, Single step",
            "experienceId": "54b7ec71-cdaf-4697-affa-f3abd672b3cf",
            "version": 1632142800000,
            "experienceType": "mobile",
            "message": "error",
            "errorId": "A6D6E248-FAFF-4789-A03C-BD7F520C1181"
        ].verifyPropertiesMatch(lastUpdate.properties)

        XCTAssertEqual(
            try XCTUnwrap(LifecycleEvent.restructure(update: lastUpdate)),
            LifecycleEvent.EventProperties(
                type: .experienceError,
                experienceID: UUID(uuidString: "54b7ec71-cdaf-4697-affa-f3abd672b3cf")!,
                experienceName: "Mock Experience: Group with 3 steps, Single step",
                errorID: UUID(uuidString: "A6D6E248-FAFF-4789-A03C-BD7F520C1181"),
                message: "error"
            ),
            "can succesfully remap the property dict"
        )
    }

    func testEvaluateStepError() throws {
        // Arrange
        UUID.generator = { UUID(uuidString: "A6D6E248-FAFF-4789-A03C-BD7F520C1181")! }

        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .failure(.step(Experience.mock, .initial, "error")))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(analyticsSubscriber.trackedUpdates, 1)
        let lastUpdate = try XCTUnwrap(analyticsSubscriber.lastUpdate)
        XCTAssertEqual(lastUpdate.type, .event(name: "appcues:v2:step_error", interactive: false))
        [
            "experienceName": "Mock Experience: Group with 3 steps, Single step",
            "experienceId": "54b7ec71-cdaf-4697-affa-f3abd672b3cf",
            "version": 1632142800000,
            "experienceType": "mobile",
            "stepType": "modal",
            "stepId": "e03ae132-91b7-4cb0-9474-7d4a0e308a07",
            "stepIndex": "0,0",
            "message": "error",
            "errorId": "A6D6E248-FAFF-4789-A03C-BD7F520C1181"
        ].verifyPropertiesMatch(lastUpdate.properties)

        XCTAssertEqual(
            try XCTUnwrap(LifecycleEvent.restructure(update: lastUpdate)),
            LifecycleEvent.EventProperties(
                type: .stepError,
                experienceID: UUID(uuidString: "54b7ec71-cdaf-4697-affa-f3abd672b3cf")!,
                experienceName: "Mock Experience: Group with 3 steps, Single step",
                stepID: UUID(uuidString: "e03ae132-91b7-4cb0-9474-7d4a0e308a07"),
                stepIndex: Experience.StepIndex(group: 0, item: 0),
                errorID: UUID(uuidString: "A6D6E248-FAFF-4789-A03C-BD7F520C1181"),
                message: "error"
            ),
            "can succesfully remap the property dict"
        )
    }

    func testEvaluateNoTransitionError() throws {
        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .failure(.noTransition(currentState: .idling)))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(analyticsSubscriber.trackedUpdates, 0)
    }
}
