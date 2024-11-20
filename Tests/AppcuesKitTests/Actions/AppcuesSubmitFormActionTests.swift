//
//  AppcuesSubmitFormActionTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-09-29.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class AppcuesSubmitFormActionTests: XCTestCase {

    var appcues: MockAppcues!

    override func setUpWithError() throws {
        appcues = MockAppcues()
    }

    func testInit() throws {
        // Act
        let action = AppcuesSubmitFormAction(configuration: AppcuesExperiencePluginConfiguration(nil, appcues: appcues))

        // Assert
        XCTAssertEqual(AppcuesSubmitFormAction.type, "@appcues/submit-form")
        XCTAssertNotNil(action)
        XCTAssertEqual(action?.skipValidation, false)
    }

    func testExecuteValidForm() async throws {
        // Arrange
        let expectedFormItem = ExperienceData.FormItem(model: ExperienceComponent.TextInputModel(
            id: UUID(),
            label: ExperienceComponent.TextModel(id: UUID(), text: "Form label", style: nil),
            errorLabel: nil,
            placeholder: nil,
            defaultValue: "default value",
            required: true,
            numberOfLines: nil,
            maxLength: nil,
            dataType: nil,
            textFieldStyle: nil,
            cursorColor: nil,
            attributeName: nil,
            style: nil))

        var updates: [TrackingUpdate] = []

        let experience = ExperienceData.mockWithForm(defaultValue: "default value")
        appcues.experienceRenderer.onExperienceData = { _ in
            experience
        }
        appcues.experienceRenderer.onStepIndex = { _ in
            .initial
        }
        appcues.analyticsPublisher.onPublish = { trackingUpdate in
            updates.append(trackingUpdate)
        }

        let action = AppcuesSubmitFormAction(appcues: appcues)

        // Act
        try await action?.execute()

        // Assert
        XCTAssertEqual(updates.count, 2)

        XCTAssertEqual(updates[0].type, .profile(interactive: false))
        XCTAssertEqual(updates[1].type, .event(name: "appcues:v2:step_interaction", interactive: false))

        [
            "_appcuesForm_form-label": "default value"
        ].verifyPropertiesMatch(updates[0].properties)

        [
            "experienceName": "Mock Experience: Single step with form",
            "experienceId": "ded7b50f-bc24-42de-a0fa-b1f10fc10d00",
            "experienceInstanceId": experience.instanceID.appcuesFormatted,
            "version": 1632142800000,
            "experienceType": "mobile",
            "stepType": "modal",
            "stepId": "6cf396f6-1f01-4449-9e38-7e845f5316c0",
            "stepIndex": "0,0",
            "trigger": "show_call",
            "interactionType": "Form Submitted",
            "interactionData": [
                "formResponse": ExperienceData.StepState(formItems: [
                    UUID(uuidString: "f002dc4f-c5fc-4439-8916-0047a5839741")!: expectedFormItem
                ])
            ]
        ].verifyPropertiesMatch(updates[1].properties)
    }


    func testExecuteUnpublishedExperience() async throws {
        // Arrange
        var loggedUpdates: [TrackingUpdate] = []

        appcues.experienceRenderer.onExperienceData = { _ in
            ExperienceData.mockWithForm(defaultValue: nil, published: false)
        }
        appcues.experienceRenderer.onStepIndex = { _ in
            .initial
        }

        appcues.analyticsPublisher.onPublish = { trackingUpdate in
            XCTFail("unexpected analytics event")
        }
        appcues.analyticsPublisher.onLog = { trackingUpdate in
            loggedUpdates.append(trackingUpdate)
        }


        let action = AppcuesSubmitFormAction(appcues: appcues)

        // Act
        try await action?.execute()

        // Assert
        XCTAssertEqual(loggedUpdates.count, 2)

        XCTAssertEqual(loggedUpdates[0].type, .profile(interactive: false))
        XCTAssertEqual(loggedUpdates[1].type, .event(name: "appcues:v2:step_interaction", interactive: false))
    }

    func testExecuteEarlyReturn() async throws {
        // Arrange
        appcues.experienceRenderer.onExperienceData = { _ in
            ExperienceData.mockWithForm(defaultValue: nil)
        }
        appcues.experienceRenderer.onStepIndex = { _ in
            // Invalid step index causes failure and early return
            Experience.StepIndex(group: 2, item: 2)
        }

        appcues.analyticsPublisher.onPublish = { trackingUpdate in
            XCTFail("unexpected analytics event")
        }

        let action = AppcuesSubmitFormAction(appcues: appcues)

        // Act
        try await action?.execute()
    }

    func testExecuteThrowsWithoutAppcuesInstance() async throws {
        // Arrange
        let action = try XCTUnwrap(AppcuesSubmitFormAction(appcues: nil))

        // Act
        await XCTAssertThrowsAsyncError(try await action.execute()) {
            XCTAssertEqual(($0 as? AppcuesTraitError)?.description, "No appcues instance")
        }
    }

    func testTransformQueueEarlyReturn() async throws {
        // Arrange
        appcues.experienceRenderer.onExperienceData = { _ in
            ExperienceData.mockWithForm(defaultValue: nil)
        }
        appcues.experienceRenderer.onStepIndex = { _ in
            // Invalid step index causes failure and early return
            Experience.StepIndex(group: 2, item: 2)
        }

        let action0 = try XCTUnwrap(AppcuesTrackAction(appcues: appcues, eventName: "My Custom Event"))
        let action = try XCTUnwrap(AppcuesSubmitFormAction(appcues: appcues))
        let action1 = try XCTUnwrap(AppcuesTrackAction(appcues: appcues, eventName: "My Custom Event"))
        let action2 = try XCTUnwrap(AppcuesTrackAction(appcues: appcues, eventName: "My Custom Event"))
        let initialQueue: [AppcuesExperienceAction] = [action0, action, action1, action2]

        // Act
        let updatedQueue = action.transformQueue(initialQueue, index: 1, inContext: appcues)

        // Assert
        XCTAssertEqual(updatedQueue.count, 4, "no change to queue")
    }

    func testTransformQueueValidForm() async throws {
        // Arrange
        appcues.experienceRenderer.onExperienceData = { _ in
            ExperienceData.mockWithForm(defaultValue: "123")
        }
        appcues.experienceRenderer.onStepIndex = { _ in
            .initial
        }

        let action0 = try XCTUnwrap(AppcuesTrackAction(appcues: appcues, eventName: "My Custom Event"))
        let action = try XCTUnwrap(AppcuesSubmitFormAction(appcues: appcues))
        let action1 = try XCTUnwrap(AppcuesTrackAction(appcues: appcues, eventName: "My Custom Event"))
        let action2 = try XCTUnwrap(AppcuesTrackAction(appcues: appcues, eventName: "My Custom Event"))
        let initialQueue: [AppcuesExperienceAction] = [action0, action, action1, action2]

        // Act
        let updatedQueue = action.transformQueue(initialQueue, index: 1, inContext: appcues)

        // Assert
        XCTAssertEqual(updatedQueue.count, 4, "no change to queue")
    }

    func testTransformQueueInvalidForm() async throws {
        // Arrange
        appcues.experienceRenderer.onExperienceData = { _ in
            ExperienceData.mockWithForm(defaultValue: nil)
        }
        appcues.experienceRenderer.onStepIndex = { _ in
            .initial
        }

        let action0 = try XCTUnwrap(AppcuesTrackAction(appcues: appcues, eventName: "My Custom Event"))
        let action = try XCTUnwrap(AppcuesSubmitFormAction(appcues: appcues))
        let action1 = try XCTUnwrap(AppcuesTrackAction(appcues: appcues, eventName: "My Custom Event"))
        let action2 = try XCTUnwrap(AppcuesTrackAction(appcues: appcues, eventName: "My Custom Event"))
        let initialQueue: [AppcuesExperienceAction] = [action0, action, action1, action2]

        // Act
        let updatedQueue = action.transformQueue(initialQueue, index: 1, inContext: appcues)

        // Assert
        XCTAssertEqual(updatedQueue.count, 1)
        XCTAssertTrue(updatedQueue[0] === action0, "only the action before submit-form remains")
    }

    func testTransformQueueInvalidFormSkipValidation() async throws {
        // Arrange
        appcues.experienceRenderer.onExperienceData = { _ in
            ExperienceData.mockWithForm(defaultValue: nil)
        }
        appcues.experienceRenderer.onStepIndex = { _ in
            .initial
        }

        let action0 = try XCTUnwrap(AppcuesTrackAction(appcues: appcues, eventName: "My Custom Event"))
        let action = try XCTUnwrap(AppcuesSubmitFormAction(appcues: appcues, skipValidation: true))
        let action1 = try XCTUnwrap(AppcuesTrackAction(appcues: appcues, eventName: "My Custom Event"))
        let action2 = try XCTUnwrap(AppcuesTrackAction(appcues: appcues, eventName: "My Custom Event"))
        let initialQueue: [AppcuesExperienceAction] = [action0, action, action1, action2]

        // Act
        let updatedQueue = action.transformQueue(initialQueue, index: 1, inContext: appcues)

        // Assert
        XCTAssertEqual(updatedQueue.count, 4)
        XCTAssertTrue(updatedQueue[0] === action0)
        XCTAssertTrue(updatedQueue[1] === action)
        XCTAssertTrue(updatedQueue[2] === action1)
        XCTAssertTrue(updatedQueue[3] === action2)
    }

    func testCustomProfileAttribute() async throws {
        // Arrange
        var updates: [TrackingUpdate] = []

        appcues.experienceRenderer.onExperienceData = { _ in
            ExperienceData.mockWithForm(defaultValue: "default value", attributeName: "myAttribute")
        }
        appcues.experienceRenderer.onStepIndex = { _ in
            .initial
        }
        appcues.analyticsPublisher.onPublish = { trackingUpdate in
            updates.append(trackingUpdate)
        }

        let action = AppcuesSubmitFormAction(appcues: appcues)

        // Act
        try await action?.execute()

        // Assert
        [
            "_appcuesForm_form-label": "default value",
            "myAttribute": "default value"
        ].verifyPropertiesMatch(updates[0].properties)
    }
}

extension AppcuesSubmitFormAction {
    convenience init?(appcues: Appcues?) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(nil, appcues: appcues))
    }
    convenience init?(appcues: Appcues?, skipValidation: Bool) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(AppcuesSubmitFormAction.Config(skipValidation: skipValidation), appcues: appcues))
    }
}
