//
//  ExperienceStateMachine+AnalyticsObserverTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-03-21.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class ExperienceStateMachine_AnalyticsObserverTests: XCTestCase {

    var appcues: MockAppcues!
    private var updates: [TrackingUpdate] = []
    var observer: ExperienceStateMachine.AnalyticsObserver!
    var analyticsExpectation: XCTestExpectation!

    override func setUpWithError() throws {
        appcues = MockAppcues()
        appcues.analyticsPublisher.onPublish = { update in
            self.updates.append(update)
            self.analyticsExpectation?.fulfill()
        }
        observer = ExperienceStateMachine.AnalyticsObserver(container: appcues.container)
    }

    override func tearDownWithError() throws {
        analyticsExpectation = nil
        updates = []
    }

    func testEvaluateIdlingState() async throws {
        // Act
        observer.stateChanged(to: .success(.idling))

        // Assert
        XCTAssertEqual(updates.count, 0)
    }

    func testEvaluateBeginningExperienceState() async throws {
        // Act
        observer.stateChanged(to: .success(.beginningExperience(ExperienceData.mock)))

        // Assert
        XCTAssertEqual(updates.count, 0)
    }

    func testEvaluateBeginningStepState() async throws {
        // Act
        observer.stateChanged(to: .success(.beginningStep(ExperienceData.mock, .initial, await ExperienceData.mock.package(), isFirst: true)))

        // Assert
        XCTAssertEqual(updates.count, 0)
    }

    func testEvaluateRenderingFirstStepState() async throws {
        // Precondition
        XCTAssertNil(appcues.storage.lastContentShownAt)

        // Arrange
        analyticsExpectation = expectation(description: "analytics updated")
        analyticsExpectation.expectedFulfillmentCount = 2

        // Act
        let experience = ExperienceData.mock
        observer.stateChanged(to: .success(.renderingStep(experience, .initial, await experience.package(), isFirst: true)))

        // Assert
        await fulfillment(of: [analyticsExpectation], timeout: 1)
        XCTAssertEqual(updates.count, 2)
        let lastUpdate = try XCTUnwrap(updates.last)
        XCTAssertEqual(lastUpdate.type, .event(name: "appcues:v2:step_seen", interactive: false))
        [
            "experienceName": "Mock Experience: Group with 3 steps, Single step",
            "experienceId": "54b7ec71-cdaf-4697-affa-f3abd672b3cf",
            "experienceInstanceId": experience.instanceID.appcuesFormatted,
            "version": 1632142800000,
            "experienceType": "mobile",
            "trigger": "show_call",
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

    func testEvaluateRenderingStepState() async throws {
        // Arrange
        analyticsExpectation = expectation(description: "analytics updated")

        // Act
        let experience = ExperienceData.mock
        observer.stateChanged(to: .success(.renderingStep(experience, .initial, await experience.package(), isFirst: false)))

        // Assert
        await fulfillment(of: [analyticsExpectation], timeout: 1)
        XCTAssertEqual(updates.count, 1)
        let lastUpdate = try XCTUnwrap(updates.last)
        XCTAssertEqual(lastUpdate.type, .event(name: "appcues:v2:step_seen", interactive: false))
        [
            "experienceName": "Mock Experience: Group with 3 steps, Single step",
            "experienceId": "54b7ec71-cdaf-4697-affa-f3abd672b3cf",
            "experienceInstanceId": experience.instanceID.appcuesFormatted,
            "version": 1632142800000,
            "experienceType": "mobile",
            "trigger": "show_call",
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

    func testEvaluateEndingStepState() async throws {
        // Arrange
        analyticsExpectation = expectation(description: "analytics updated")

        // Act
        let experience = ExperienceData.mock
        observer.stateChanged(to: .success(.endingStep(experience, .initial, await experience.package(), markComplete: true)))

        // Assert
        await fulfillment(of: [analyticsExpectation], timeout: 1)
        XCTAssertEqual(updates.count, 1)

        let lastUpdate = try XCTUnwrap(updates.last)
        XCTAssertEqual(lastUpdate.type, .event(name: "appcues:v2:step_completed", interactive: false))
        [
            "experienceName": "Mock Experience: Group with 3 steps, Single step",
            "experienceId": "54b7ec71-cdaf-4697-affa-f3abd672b3cf",
            "experienceInstanceId": experience.instanceID.appcuesFormatted,
            "version": 1632142800000,
            "experienceType": "mobile",
            "trigger": "show_call",
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

    func testEvaluateEndingStepStateWhenIncomplete() async throws {
        // Act
        observer.stateChanged(to: .success(.endingStep(ExperienceData.mock, .initial, await ExperienceData.mock.package(), markComplete: false)))

        // Assert
        XCTAssertEqual(updates.count, 0)
    }

    func testEvaluateEndingExperienceState() async throws {
        // Arrange
        analyticsExpectation = expectation(description: "analytics updated")

        // Act
        let experience = ExperienceData.mock
        observer.stateChanged(to: .success(.endingExperience(experience, .initial, markComplete: false)))

        // Assert
        await fulfillment(of: [analyticsExpectation], timeout: 1)
        XCTAssertEqual(updates.count, 1)
        let lastUpdate = try XCTUnwrap(updates.last)
        XCTAssertEqual(lastUpdate.type, .event(name: "appcues:v2:experience_dismissed", interactive: false))
        [
            "experienceName": "Mock Experience: Group with 3 steps, Single step",
            "experienceId": "54b7ec71-cdaf-4697-affa-f3abd672b3cf",
            "experienceInstanceId": experience.instanceID.appcuesFormatted,
            "version": 1632142800000,
            "experienceType": "mobile",
            "trigger": "show_call",
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

    func testEvaluateEndingExperienceStateMarkComplete() async throws {
        // Arrange
        analyticsExpectation = expectation(description: "analytics updated")

        // Act
        let experience = ExperienceData.mock
        observer.stateChanged(to: .success(.endingExperience(experience, .initial, markComplete: true)))

        // Assert
        await fulfillment(of: [analyticsExpectation], timeout: 1)
        XCTAssertEqual(updates.count, 1)
        let lastUpdate = try XCTUnwrap(updates.last)
        XCTAssertEqual(lastUpdate.type, .event(name: "appcues:v2:experience_completed", interactive: false))
        [
            "experienceName": "Mock Experience: Group with 3 steps, Single step",
            "experienceId": "54b7ec71-cdaf-4697-affa-f3abd672b3cf",
            "experienceInstanceId": experience.instanceID.appcuesFormatted,
            "version": 1632142800000,
            "experienceType": "mobile",
            "trigger": "show_call",
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

    func testEvaluateEndingExperienceLastStepState() async throws {
        // Arrange
        analyticsExpectation = expectation(description: "analytics updated")

        // Act
        let experience = ExperienceData.mock
        observer.stateChanged(to: .success(.endingExperience(experience, Experience.StepIndex(group: 1, item: 0), markComplete: true)))

        // Assert
        await fulfillment(of: [analyticsExpectation], timeout: 1)
        XCTAssertEqual(updates.count, 1)
        let lastUpdate = try XCTUnwrap(updates.last)
        XCTAssertEqual(lastUpdate.type, .event(name: "appcues:v2:experience_completed", interactive: false))
        [
            "experienceName": "Mock Experience: Group with 3 steps, Single step",
            "experienceId": "54b7ec71-cdaf-4697-affa-f3abd672b3cf",
            "experienceInstanceId": experience.instanceID.appcuesFormatted,
            "version": 1632142800000,
            "experienceType": "mobile",
            "trigger": "show_call",
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

    func testEvaluateExperienceError() async throws {
        // Arrange
        analyticsExpectation = expectation(description: "analytics updated")
        let experience = ExperienceData.mock

        // Act
        observer.stateChanged(to: .failure(.experience(experience, "error")))

        // Assert
        await fulfillment(of: [analyticsExpectation], timeout: 1)
        XCTAssertEqual(updates.count, 1)
        let lastUpdate = try XCTUnwrap(updates.last)
        XCTAssertEqual(lastUpdate.type, .event(name: "appcues:v2:experience_error", interactive: false))
        [
            "experienceName": "Mock Experience: Group with 3 steps, Single step",
            "experienceId": "54b7ec71-cdaf-4697-affa-f3abd672b3cf",
            "experienceInstanceId": experience.instanceID.appcuesFormatted,
            "version": 1632142800000,
            "experienceType": "mobile",
            "trigger": "show_call",
            "localeName": "English",
            "localeId": "en",
            "message": "error",
            "errorId": SomeUUID()
        ].verifyPropertiesMatch(lastUpdate.properties)

        // Pull the error ID from the update being tested because it's uniquely generated
        let errorID = try XCTUnwrap(UUID(uuidString: lastUpdate.properties?["errorId"] as? String ?? ""))
        XCTAssertEqual(
            try XCTUnwrap(StructuredLifecycleProperties(update: lastUpdate)),
            StructuredLifecycleProperties(
                type: .experienceError,
                experienceID: UUID(uuidString: "54b7ec71-cdaf-4697-affa-f3abd672b3cf")!,
                experienceName: "Mock Experience: Group with 3 steps, Single step",
                experienceInstanceID: experience.instanceID,
                errorID: errorID,
                message: "error"
            ),
            "can successfully remap the property dict"
        )
    }

    func testEvaluateStepError() async throws {
        // Arrange
        analyticsExpectation = expectation(description: "analytics updated")
        let experience = ExperienceData.mock

        // Act
        observer.stateChanged(to: .failure(.step(experience, .initial, "error")))

        // Assert
        await fulfillment(of: [analyticsExpectation], timeout: 1)
        XCTAssertEqual(updates.count, 1)
        let lastUpdate = try XCTUnwrap(updates.last)
        XCTAssertEqual(lastUpdate.type, .event(name: "appcues:v2:step_error", interactive: false))
        [
            "experienceName": "Mock Experience: Group with 3 steps, Single step",
            "experienceId": "54b7ec71-cdaf-4697-affa-f3abd672b3cf",
            "experienceInstanceId": experience.instanceID.appcuesFormatted,
            "version": 1632142800000,
            "experienceType": "mobile",
            "trigger": "show_call",
            "localeName": "English",
            "localeId": "en",
            "stepType": "modal",
            "stepId": "e03ae132-91b7-4cb0-9474-7d4a0e308a07",
            "stepIndex": "0,0",
            "message": "error",
            "errorId": SomeUUID()
        ].verifyPropertiesMatch(lastUpdate.properties)

        // Pull the error ID from the update being tested because it's uniquely generated
        let errorID = try XCTUnwrap(UUID(uuidString: lastUpdate.properties?["errorId"] as? String ?? ""))
        XCTAssertEqual(
            try XCTUnwrap(StructuredLifecycleProperties(update: lastUpdate)),
            StructuredLifecycleProperties(
                type: .stepError,
                experienceID: UUID(uuidString: "54b7ec71-cdaf-4697-affa-f3abd672b3cf")!,
                experienceName: "Mock Experience: Group with 3 steps, Single step",
                experienceInstanceID: experience.instanceID,
                stepID: UUID(uuidString: "e03ae132-91b7-4cb0-9474-7d4a0e308a07"),
                stepIndex: Experience.StepIndex(group: 0, item: 0),
                errorID: errorID,
                message: "error"
            ),
            "can successfully remap the property dict"
        )
    }

    func testExperienceErrorAndRecovery() async throws {
        // Arrange
        analyticsExpectation = expectation(description: "analytics updated")
        analyticsExpectation.expectedFulfillmentCount = 2

        let experienceData = ExperienceData.mock

        // Act
        observer.trackRecoverableError(experience: experienceData, message: "oh no")
        observer.trackErrorRecovery(ifErrorOn: experienceData)

        // Assert
        await fulfillment(of: [analyticsExpectation], timeout: 1)
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
            "trigger": "show_call",
            "localeName": "English",
            "localeId": "en",
            "errorId": SomeUUID(),
            "message": "oh no"
        ].verifyPropertiesMatch(errorUpdate.properties)

        XCTAssertEqual(recoveryUpdate.type, .event(name: "appcues:v2:experience_recovered", interactive: false))
        [
            "experienceName": "Mock Experience: Group with 3 steps, Single step",
            "experienceId": "54b7ec71-cdaf-4697-affa-f3abd672b3cf",
            "experienceInstanceId": experienceData.instanceID.appcuesFormatted,
            "version": 1632142800000,
            "experienceType": "mobile",
            "trigger": "show_call",
            "localeName": "English",
            "localeId": "en",
            "errorId": SomeUUID()
        ].verifyPropertiesMatch(recoveryUpdate.properties)
    }

    func testUnpublishedExperienceErrorAndRecovery() async throws {
        // Arrange
        let experienceData = ExperienceData(.mock, trigger: .showCall, published: false)

        // Act
        observer.trackRecoverableError(experience: experienceData, message: "oh no")
        observer.trackErrorRecovery(ifErrorOn: experienceData)

        // Assert
        XCTAssertEqual(updates.count, 0)
    }

    func testStepErrorAndRecovery() async throws {
        // Arrange
        analyticsExpectation = expectation(description: "analytics updated")
        analyticsExpectation.expectedFulfillmentCount = 4

        let experience = ExperienceData.mock
        let package = await experience.package()

        // Act
        // simulates the same recoverable step error occurring multiple times, then a successful render of the step
        observer.stateChanged(to: .failure(.step(experience, .initial, "recoverable step error", recoverable: true)))
        observer.stateChanged(to: .failure(.step(experience, .initial, "recoverable step error", recoverable: true)))
        observer.stateChanged(to: .success(.renderingStep(experience, .initial, package, isFirst: true)))

        // Assert
        await fulfillment(of: [analyticsExpectation], timeout: 1)
        XCTAssertEqual(updates.count, 4) // step_error, experience_started, step_recovered, step_seen
        let stepError = try XCTUnwrap(updates[safe: 0])
        let experienceStarted = try XCTUnwrap(updates[safe: 1])
        let stepRecovered = try XCTUnwrap(updates[safe: 2])
        let stepSeen = try XCTUnwrap(updates[safe: 3])
        XCTAssertEqual(stepError.type, .event(name: "appcues:v2:step_error", interactive: false))
        XCTAssertEqual(experienceStarted.type, .event(name: "appcues:v2:experience_started", interactive: false))
        XCTAssertEqual(stepRecovered.type, .event(name: "appcues:v2:step_recovered", interactive: false))
        XCTAssertEqual(stepSeen.type, .event(name: "appcues:v2:step_seen", interactive: false))
        [
            "experienceName": "Mock Experience: Group with 3 steps, Single step",
            "experienceId": "54b7ec71-cdaf-4697-affa-f3abd672b3cf",
            "experienceInstanceId": experience.instanceID.appcuesFormatted,
            "version": 1632142800000,
            "experienceType": "mobile",
            "trigger": "show_call",
            "localeName": "English",
            "localeId": "en",
            "stepType": "modal",
            "stepId": "e03ae132-91b7-4cb0-9474-7d4a0e308a07",
            "stepIndex": "0,0",
            "message": "recoverable step error",
            "errorId": SomeUUID()
        ].verifyPropertiesMatch(stepError.properties)
        [
            "experienceName": "Mock Experience: Group with 3 steps, Single step",
            "experienceId": "54b7ec71-cdaf-4697-affa-f3abd672b3cf",
            "experienceInstanceId": experience.instanceID.appcuesFormatted,
            "version": 1632142800000,
            "experienceType": "mobile",
            "trigger": "show_call",
            "localeName": "English",
            "localeId": "en",
            "stepType": "modal",
            "stepId": "e03ae132-91b7-4cb0-9474-7d4a0e308a07",
            "stepIndex": "0,0",
            "errorId": SomeUUID()
        ].verifyPropertiesMatch(stepRecovered.properties)
    }

}
