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
    private var updates: [TrackingUpdate] = []
    var observer: ExperienceStateMachine.AnalyticsObserver!

    override func setUpWithError() throws {
        appcues = MockAppcues()
        appcues.analyticsPublisher.onPublish = { update in
            self.updates.append(update)
        }
        observer = ExperienceStateMachine.AnalyticsObserver(container: appcues.container)
    }

    override func tearDownWithError() throws {
        // Reset fixed UUID
        UUID.generator = UUID.init

        updates = []
    }

    func testEvaluateIdlingState() throws {
        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.idling))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(updates.count, 0)
    }

    func testEvaluateBeginningExperienceState() throws {
        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.beginningExperience(ExperienceData.mock)))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(updates.count, 0)
    }

    func testEvaluateBeginningStepState() throws {
        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.beginningStep(ExperienceData.mock, .initial, ExperienceData.mock.package(), isFirst: true)))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(updates.count, 0)
    }

    func testEvaluateRenderingFirstStepState() throws {
        // Precondition
        XCTAssertNil(appcues.storage.lastContentShownAt)

        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.renderingStep(ExperienceData.mock, .initial, ExperienceData.mock.package(), isFirst: true)))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(updates.count, 2)
        let lastUpdate = try XCTUnwrap(updates.last)
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
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.renderingStep(ExperienceData.mock, .initial, ExperienceData.mock.package(), isFirst: false)))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(updates.count, 1)
        let lastUpdate = try XCTUnwrap(updates.last)
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
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.endingStep(ExperienceData.mock, .initial, ExperienceData.mock.package())))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(updates.count, 1)

        let lastUpdate = try XCTUnwrap(updates.last)
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

    func testEvaluateEndingStepStateWithForm() throws {
        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.endingStep(ExperienceData.mockWithForm, .initial, ExperienceData.mock.package())))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(updates.count, 3)

        XCTAssertEqual(updates[0].type, .profile)
        XCTAssertEqual(updates[1].type, .event(name: "appcues:v2:step_interaction", interactive: false))
        XCTAssertEqual(updates[2].type, .event(name: "appcues:v2:step_completed", interactive: false))

        [
            "_appcuesForm_form-label": "default value"
        ].verifyPropertiesMatch(updates[0].properties)

        [
            "experienceName": "Mock Experience: Single step with form",
            "experienceId": "ded7b50f-bc24-42de-a0fa-b1f10fc10d00",
            "version": 1632142800000,
            "experienceType": "mobile",
            "stepType": "modal",
            "stepId": "6cf396f6-1f01-4449-9e38-7e845f5316c0",
            "stepIndex": "0,0",
            "interactionType": "Form Submitted",
            "interactionData": [
                "formResponse": ExperienceData.StepState(formItems: [
                    UUID(uuidString: "f002dc4f-c5fc-4439-8916-0047a5839741")!: ExperienceData.FormItem(
                        type: "textInput",
                        label: "Form label",
                        value: .single("default value"),
                        required: true)
                ])
            ]
        ].verifyPropertiesMatch(updates[1].properties)

        [
            "experienceName": "Mock Experience: Single step with form",
            "experienceId": "ded7b50f-bc24-42de-a0fa-b1f10fc10d00",
            "version": 1632142800000,
            "experienceType": "mobile",
            "stepType": "modal",
            "stepId": "6cf396f6-1f01-4449-9e38-7e845f5316c0",
            "stepIndex": "0,0"
        ].verifyPropertiesMatch(updates[2].properties)
    }

    func testEvaluateEndingExperienceState() throws {
        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.endingExperience(ExperienceData.mock, .initial, markComplete: false)))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(updates.count, 1)
        let lastUpdate = try XCTUnwrap(updates.last)
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
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.endingExperience(ExperienceData.mock, .initial, markComplete: true)))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(updates.count, 1)
        let lastUpdate = try XCTUnwrap(updates.last)
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
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.endingExperience(ExperienceData.mock, Experience.StepIndex(group: 1, item: 0), markComplete: false)))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(updates.count, 1)
        let lastUpdate = try XCTUnwrap(updates.last)
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
        let isCompleted = observer.evaluateIfSatisfied(result: .failure(.experience(ExperienceData.mock, "error")))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(updates.count, 1)
        let lastUpdate = try XCTUnwrap(updates.last)
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
        let isCompleted = observer.evaluateIfSatisfied(result: .failure(.step(ExperienceData.mock, .initial, "error")))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(updates.count, 1)
        let lastUpdate = try XCTUnwrap(updates.last)
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
        XCTAssertEqual(updates.count, 0)
    }
}
