//
//  AppcuesSubmitFormActionTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-09-29.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

@available(iOS 13.0, *)
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

    func testExecuteValidForm() throws {
        // Arrange
        let expectedFormItem = ExperienceData.FormItem(model: ExperienceComponent.TextInputModel(
            id: UUID(),
            label: ExperienceComponent.TextModel(id: UUID(), text: "Form label - mock", style: nil),
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

        var completionCount = 0
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
        action?.execute(completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(updates.count, 2)

        XCTAssertEqual(updates[0].type, .profile(interactive: false))
        XCTAssertEqual(updates[1].type, .event(name: "appcues:v2:step_interaction", interactive: false))

        [
            "_appcuesForm_form-label-mock": "default value"
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
                    ExperienceComponent.TextInputModel.mockId: expectedFormItem
                ])
            ]
        ].verifyPropertiesMatch(updates[1].properties)
    }


    func testExecuteUnpublishedExperience() throws {
        // Arrange
        var completionCount = 0
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
        action?.execute(completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(loggedUpdates.count, 2)

        XCTAssertEqual(loggedUpdates[0].type, .profile(interactive: false))
        XCTAssertEqual(loggedUpdates[1].type, .event(name: "appcues:v2:step_interaction", interactive: false))
    }

    func testExecuteEarlyReturn() throws {
        // Arrange
        var completionCount = 0

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
        action?.execute(completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
    }

    func testExecuteCompletesWithoutAppcuesInstance() throws {
        // Arrange
        var completionCount = 0
        let action = try XCTUnwrap(AppcuesSubmitFormAction(appcues: nil))

        // Act
        action.execute(completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
    }

    func testTransformQueueEarlyReturn() throws {
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

    func testTransformQueueValidForm() throws {
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

    func testTransformQueueInvalidForm() throws {
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

    func testTransformQueueInvalidFormSkipValidation() throws {
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

    func testCustomProfileAttribute() throws {
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
        action?.execute(completion: { })

        // Assert
        [
            "_appcuesForm_form-label-mock": "default value",
            "myAttribute": "default value"
        ].verifyPropertiesMatch(updates[0].properties)
    }
}

@available(iOS 13.0, *)
extension AppcuesSubmitFormAction {
    convenience init?(appcues: Appcues?) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(nil, appcues: appcues))
    }
    convenience init?(appcues: Appcues?, skipValidation: Bool) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(AppcuesSubmitFormAction.Config(skipValidation: skipValidation), appcues: appcues))
    }
}
