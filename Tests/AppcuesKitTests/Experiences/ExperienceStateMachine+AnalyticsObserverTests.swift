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
        let experience = ExperienceData.mock
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.renderingStep(experience, .initial, experience.package(), isFirst: true)))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(updates.count, 2)
        let lastUpdate = try XCTUnwrap(updates.last)
        XCTAssertEqual(lastUpdate.type, .event(name: "appcues:v2:step_seen", interactive: false))
        [
            "experienceName": "Mock Experience: Group with 3 steps, Single step",
            "experienceId": "54b7ec71-cdaf-4697-affa-f3abd672b3cf",
            "experienceInstanceId": experience.instanceID.appcuesFormatted,
            "version": 1632142800000,
            "experienceType": "mobile",
            "localeName": "English",
            "localeId": "en",
            "stepType": "modal",
            "stepId": "e03ae132-91b7-4cb0-9474-7d4a0e308a07",
            "stepIndex": "0,0"
        ].verifyPropertiesMatch(lastUpdate.properties)
        XCTAssertNotNil(appcues.storage.lastContentShownAt)

        XCTAssertEqual(
            try XCTUnwrap(StructuredLifecycleProperties(update: lastUpdate)),
            StructuredLifecycleProperties(
                type: .stepSeen,
                experienceID: UUID(uuidString: "54b7ec71-cdaf-4697-affa-f3abd672b3cf")!,
                experienceName: "Mock Experience: Group with 3 steps, Single step",
                experienceInstanceID: experience.instanceID,
                stepID: UUID(uuidString: "e03ae132-91b7-4cb0-9474-7d4a0e308a07"),
                stepIndex: Experience.StepIndex(group: 0, item: 0)
            ),
            "can successfully remap the property dict"
        )
    }

    func testEvaluateRenderingStepState() throws {
        // Act
        let experience = ExperienceData.mock
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.renderingStep(experience, .initial, experience.package(), isFirst: false)))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(updates.count, 1)
        let lastUpdate = try XCTUnwrap(updates.last)
        XCTAssertEqual(lastUpdate.type, .event(name: "appcues:v2:step_seen", interactive: false))
        [
            "experienceName": "Mock Experience: Group with 3 steps, Single step",
            "experienceId": "54b7ec71-cdaf-4697-affa-f3abd672b3cf",
            "experienceInstanceId": experience.instanceID.appcuesFormatted,
            "version": 1632142800000,
            "experienceType": "mobile",
            "localeName": "English",
            "localeId": "en",
            "stepType": "modal",
            "stepId": "e03ae132-91b7-4cb0-9474-7d4a0e308a07",
            "stepIndex": "0,0"
        ].verifyPropertiesMatch(lastUpdate.properties)

        XCTAssertEqual(
            try XCTUnwrap(StructuredLifecycleProperties(update: lastUpdate)),
            StructuredLifecycleProperties(
                type: .stepSeen,
                experienceID: UUID(uuidString: "54b7ec71-cdaf-4697-affa-f3abd672b3cf")!,
                experienceName: "Mock Experience: Group with 3 steps, Single step",
                experienceInstanceID: experience.instanceID,
                stepID: UUID(uuidString: "e03ae132-91b7-4cb0-9474-7d4a0e308a07"),
                stepIndex: Experience.StepIndex(group: 0, item: 0)
            ),
            "can successfully remap the property dict"
        )
    }

    func testEvaluateEndingStepState() throws {
        // Act
        let experience = ExperienceData.mock
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.endingStep(experience, .initial, experience.package(), markComplete: true)))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(updates.count, 1)

        let lastUpdate = try XCTUnwrap(updates.last)
        XCTAssertEqual(lastUpdate.type, .event(name: "appcues:v2:step_completed", interactive: false))
        [
            "experienceName": "Mock Experience: Group with 3 steps, Single step",
            "experienceId": "54b7ec71-cdaf-4697-affa-f3abd672b3cf",
            "experienceInstanceId": experience.instanceID.appcuesFormatted,
            "version": 1632142800000,
            "experienceType": "mobile",
            "localeName": "English",
            "localeId": "en",
            "stepType": "modal",
            "stepId": "e03ae132-91b7-4cb0-9474-7d4a0e308a07",
            "stepIndex": "0,0"
        ].verifyPropertiesMatch(lastUpdate.properties)

        XCTAssertEqual(
            try XCTUnwrap(StructuredLifecycleProperties(update: lastUpdate)),
            StructuredLifecycleProperties(
                type: .stepCompleted,
                experienceID: UUID(uuidString: "54b7ec71-cdaf-4697-affa-f3abd672b3cf")!,
                experienceName: "Mock Experience: Group with 3 steps, Single step",
                experienceInstanceID: experience.instanceID,
                stepID: UUID(uuidString: "e03ae132-91b7-4cb0-9474-7d4a0e308a07"),
                stepIndex: Experience.StepIndex(group: 0, item: 0)
            ),
            "can successfully remap the property dict"
        )
    }

    func testEvaluateEndingStepStateWhenIncomplete() throws {
        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.endingStep(ExperienceData.mock, .initial, ExperienceData.mock.package(), markComplete: false)))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(updates.count, 0)
    }

    func testEvaluateEndingExperienceState() throws {
        // Act
        let experience = ExperienceData.mock
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.endingExperience(experience, .initial, markComplete: false)))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(updates.count, 1)
        let lastUpdate = try XCTUnwrap(updates.last)
        XCTAssertEqual(lastUpdate.type, .event(name: "appcues:v2:experience_dismissed", interactive: false))
        [
            "experienceName": "Mock Experience: Group with 3 steps, Single step",
            "experienceId": "54b7ec71-cdaf-4697-affa-f3abd672b3cf",
            "experienceInstanceId": experience.instanceID.appcuesFormatted,
            "version": 1632142800000,
            "experienceType": "mobile",
            "localeName": "English",
            "localeId": "en",
            "stepType": "modal",
            "stepId": "e03ae132-91b7-4cb0-9474-7d4a0e308a07",
            "stepIndex": "0,0"
        ].verifyPropertiesMatch(lastUpdate.properties)

        XCTAssertEqual(
            try XCTUnwrap(StructuredLifecycleProperties(update: lastUpdate)),
            StructuredLifecycleProperties(
                type: .experienceDismissed,
                experienceID: UUID(uuidString: "54b7ec71-cdaf-4697-affa-f3abd672b3cf")!,
                experienceName: "Mock Experience: Group with 3 steps, Single step",
                experienceInstanceID: experience.instanceID,
                stepID: UUID(uuidString: "e03ae132-91b7-4cb0-9474-7d4a0e308a07"),
                stepIndex: Experience.StepIndex(group: 0, item: 0)
            ),
            "can successfully remap the property dict"
        )
    }

    func testEvaluateEndingExperienceStateMarkComplete() throws {
        // Act
        let experience = ExperienceData.mock
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.endingExperience(experience, .initial, markComplete: true)))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(updates.count, 1)
        let lastUpdate = try XCTUnwrap(updates.last)
        XCTAssertEqual(lastUpdate.type, .event(name: "appcues:v2:experience_completed", interactive: false))
        [
            "experienceName": "Mock Experience: Group with 3 steps, Single step",
            "experienceId": "54b7ec71-cdaf-4697-affa-f3abd672b3cf",
            "experienceInstanceId": experience.instanceID.appcuesFormatted,
            "version": 1632142800000,
            "experienceType": "mobile",
            "localeName": "English",
            "localeId": "en"
        ].verifyPropertiesMatch(lastUpdate.properties)

        XCTAssertEqual(
            try XCTUnwrap(StructuredLifecycleProperties(update: lastUpdate)),
            StructuredLifecycleProperties(
                type: .experienceCompleted,
                experienceID: UUID(uuidString: "54b7ec71-cdaf-4697-affa-f3abd672b3cf")!,
                experienceName: "Mock Experience: Group with 3 steps, Single step",
                experienceInstanceID: experience.instanceID
            ),
            "can successfully remap the property dict"
        )
    }

    func testEvaluateEndingExperienceLastStepState() throws {
        // Act
        let experience = ExperienceData.mock
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.endingExperience(experience, Experience.StepIndex(group: 1, item: 0), markComplete: true)))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(updates.count, 1)
        let lastUpdate = try XCTUnwrap(updates.last)
        XCTAssertEqual(lastUpdate.type, .event(name: "appcues:v2:experience_completed", interactive: false))
        [
            "experienceName": "Mock Experience: Group with 3 steps, Single step",
            "experienceId": "54b7ec71-cdaf-4697-affa-f3abd672b3cf",
            "experienceInstanceId": experience.instanceID.appcuesFormatted,
            "version": 1632142800000,
            "experienceType": "mobile",
            "localeName": "English",
            "localeId": "en"
        ].verifyPropertiesMatch(lastUpdate.properties)

        XCTAssertEqual(
            try XCTUnwrap(StructuredLifecycleProperties(update: lastUpdate)),
            StructuredLifecycleProperties(
                type: .experienceCompleted,
                experienceID: UUID(uuidString: "54b7ec71-cdaf-4697-affa-f3abd672b3cf")!,
                experienceName: "Mock Experience: Group with 3 steps, Single step",
                experienceInstanceID: experience.instanceID
            ),
            "can successfully remap the property dict"
        )
    }

    func testEvaluateExperienceError() throws {
        // Arrange
        let experience = ExperienceData.mock
        UUID.generator = { UUID(uuidString: "A6D6E248-FAFF-4789-A03C-BD7F520C1181")! }

        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .failure(.experience(experience, "error")))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(updates.count, 1)
        let lastUpdate = try XCTUnwrap(updates.last)
        XCTAssertEqual(lastUpdate.type, .event(name: "appcues:v2:experience_error", interactive: false))
        [
            "experienceName": "Mock Experience: Group with 3 steps, Single step",
            "experienceId": "54b7ec71-cdaf-4697-affa-f3abd672b3cf",
            "experienceInstanceId": experience.instanceID.appcuesFormatted,
            "version": 1632142800000,
            "experienceType": "mobile",
            "localeName": "English",
            "localeId": "en",
            "message": "error",
            "errorId": "a6d6e248-faff-4789-a03c-bd7f520c1181"
        ].verifyPropertiesMatch(lastUpdate.properties)

        XCTAssertEqual(
            try XCTUnwrap(StructuredLifecycleProperties(update: lastUpdate)),
            StructuredLifecycleProperties(
                type: .experienceError,
                experienceID: UUID(uuidString: "54b7ec71-cdaf-4697-affa-f3abd672b3cf")!,
                experienceName: "Mock Experience: Group with 3 steps, Single step",
                experienceInstanceID: experience.instanceID,
                errorID: UUID(uuidString: "A6D6E248-FAFF-4789-A03C-BD7F520C1181"),
                message: "error"
            ),
            "can successfully remap the property dict"
        )
    }

    func testEvaluateStepError() throws {
        // Arrange
        let experience = ExperienceData.mock
        UUID.generator = { UUID(uuidString: "A6D6E248-FAFF-4789-A03C-BD7F520C1181")! }

        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .failure(.step(experience, .initial, "error")))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(updates.count, 1)
        let lastUpdate = try XCTUnwrap(updates.last)
        XCTAssertEqual(lastUpdate.type, .event(name: "appcues:v2:step_error", interactive: false))
        [
            "experienceName": "Mock Experience: Group with 3 steps, Single step",
            "experienceId": "54b7ec71-cdaf-4697-affa-f3abd672b3cf",
            "experienceInstanceId": experience.instanceID.appcuesFormatted,
            "version": 1632142800000,
            "experienceType": "mobile",
            "localeName": "English",
            "localeId": "en",
            "stepType": "modal",
            "stepId": "e03ae132-91b7-4cb0-9474-7d4a0e308a07",
            "stepIndex": "0,0",
            "message": "error",
            "errorId": "a6d6e248-faff-4789-a03c-bd7f520c1181"
        ].verifyPropertiesMatch(lastUpdate.properties)

        XCTAssertEqual(
            try XCTUnwrap(StructuredLifecycleProperties(update: lastUpdate)),
            StructuredLifecycleProperties(
                type: .stepError,
                experienceID: UUID(uuidString: "54b7ec71-cdaf-4697-affa-f3abd672b3cf")!,
                experienceName: "Mock Experience: Group with 3 steps, Single step",
                experienceInstanceID: experience.instanceID,
                stepID: UUID(uuidString: "e03ae132-91b7-4cb0-9474-7d4a0e308a07"),
                stepIndex: Experience.StepIndex(group: 0, item: 0),
                errorID: UUID(uuidString: "A6D6E248-FAFF-4789-A03C-BD7F520C1181"),
                message: "error"
            ),
            "can successfully remap the property dict"
        )
    }

    func testEvaluateNoTransitionError() throws {
        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .failure(.noTransition(currentState: .idling)))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(updates.count, 0)
    }

    func testExperienceErrorAndRecovery() throws {
        // Arrange
        UUID.generator = { UUID(uuidString: "2e044aa2-130f-4260-80c2-a36092a88aff")! }

        let experienceData = ExperienceData.mock

        // Act
        observer.trackRecoverableError(experience: experienceData, message: "oh no")
        observer.trackErrorRecovery(ifErrorOn: experienceData)

        // Assert
        XCTAssertEqual(updates.count, 2)
        let errorUpdate = try XCTUnwrap(updates.first)
        let recoveryUpdate = try XCTUnwrap(updates.last)

        XCTAssertEqual(errorUpdate.type, .event(name: "appcues:v2:experience_error", interactive: false))
        [
            "experienceName": "Mock Experience: Group with 3 steps, Single step",
            "experienceId": "54b7ec71-cdaf-4697-affa-f3abd672b3cf",
            "experienceInstanceId": experienceData.instanceID.appcuesFormatted,
            "version": 1632142800000,
            "experienceType": "mobile",
            "localeName": "English",
            "localeId": "en",
            "errorId": "2e044aa2-130f-4260-80c2-a36092a88aff",
            "message": "oh no"
        ].verifyPropertiesMatch(errorUpdate.properties)

        XCTAssertEqual(recoveryUpdate.type, .event(name: "appcues:v2:experience_recovered", interactive: false))
        [
            "experienceName": "Mock Experience: Group with 3 steps, Single step",
            "experienceId": "54b7ec71-cdaf-4697-affa-f3abd672b3cf",
            "experienceInstanceId": experienceData.instanceID.appcuesFormatted,
            "version": 1632142800000,
            "experienceType": "mobile",
            "localeName": "English",
            "localeId": "en",
            "errorId": "2e044aa2-130f-4260-80c2-a36092a88aff"
        ].verifyPropertiesMatch(recoveryUpdate.properties)
    }

    func testUnpublishedExperienceErrorAndRecovery() throws {
        // Arrange
        UUID.generator = { UUID(uuidString: "2e044aa2-130f-4260-80c2-a36092a88aff")! }

        let experienceData = ExperienceData(.mock, trigger: .showCall, published: false)

        // Act
        observer.trackRecoverableError(experience: experienceData, message: "oh no")
        observer.trackErrorRecovery(ifErrorOn: experienceData)

        // Assert
        XCTAssertEqual(updates.count, 0)
    }

}
