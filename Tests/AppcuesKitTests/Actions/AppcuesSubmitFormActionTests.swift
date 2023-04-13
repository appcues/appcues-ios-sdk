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
        let action = AppcuesSubmitFormAction(configuration: AppcuesExperiencePluginConfiguration(nil))

        // Assert
        XCTAssertEqual(AppcuesSubmitFormAction.type, "@appcues/submit-form")
        XCTAssertNotNil(action)
        XCTAssertEqual(action?.skipValidation, false)
    }

    func testExecuteValidForm() throws {
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

        var completionCount = 0
        var updates: [TrackingUpdate] = []

        appcues.experienceRenderer.onGetCurrentExperienceData = {
            ExperienceData.mockWithForm(defaultValue: "default value")
        }
        appcues.experienceRenderer.onGetCurrentStepIndex = {
            .initial
        }
        appcues.analyticsPublisher.onPublish = { trackingUpdate in
            updates.append(trackingUpdate)
        }

        let action = AppcuesSubmitFormAction()

        // Act
        action?.execute(inContext: appcues, completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(updates.count, 2)

        XCTAssertEqual(updates[0].type, .profile(interactive: false))
        XCTAssertEqual(updates[1].type, .event(name: "appcues:v2:step_interaction", interactive: false))

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
                    UUID(uuidString: "f002dc4f-c5fc-4439-8916-0047a5839741")!: expectedFormItem
                ])
            ]
        ].verifyPropertiesMatch(updates[1].properties)
    }

    func testTransformQueueInvalidForm() throws {
        // Arrange
        appcues.experienceRenderer.onGetCurrentExperienceData = {
            ExperienceData.mockWithForm(defaultValue: nil)
        }
        appcues.experienceRenderer.onGetCurrentStepIndex = {
            .initial
        }

        let action0 = try XCTUnwrap(AppcuesTrackAction(eventName: "My Custom Event"))
        let action = try XCTUnwrap(AppcuesSubmitFormAction())
        let action1 = try XCTUnwrap(AppcuesTrackAction(eventName: "My Custom Event"))
        let action2 = try XCTUnwrap(AppcuesTrackAction(eventName: "My Custom Event"))
        let initialQueue: [AppcuesExperienceAction] = [action0, action, action1, action2]

        // Act
        let updatedQueue = action.transformQueue(initialQueue, index: 1, inContext: appcues)

        // Assert
        XCTAssertEqual(updatedQueue.count, 1)
        XCTAssertTrue(updatedQueue[0] === action0, "only the action before submit-form remains")
    }

    func testTransformQueueInvalidFormSkipValidation() throws {
        // Arrange
        appcues.experienceRenderer.onGetCurrentExperienceData = {
            ExperienceData.mockWithForm(defaultValue: nil)
        }
        appcues.experienceRenderer.onGetCurrentStepIndex = {
            .initial
        }

        let action0 = try XCTUnwrap(AppcuesTrackAction(eventName: "My Custom Event"))
        let action = try XCTUnwrap(AppcuesSubmitFormAction(skipValidation: true))
        let action1 = try XCTUnwrap(AppcuesTrackAction(eventName: "My Custom Event"))
        let action2 = try XCTUnwrap(AppcuesTrackAction(eventName: "My Custom Event"))
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

        appcues.experienceRenderer.onGetCurrentExperienceData = {
            ExperienceData.mockWithForm(defaultValue: "default value", attributeName: "myAttribute")
        }
        appcues.experienceRenderer.onGetCurrentStepIndex = {
            .initial
        }
        appcues.analyticsPublisher.onPublish = { trackingUpdate in
            updates.append(trackingUpdate)
        }

        let action = AppcuesSubmitFormAction()

        // Act
        action?.execute(inContext: appcues, completion: { })

        // Assert
        [
            "_appcuesForm_form-label": "default value",
            "myAttribute": "default value"
        ].verifyPropertiesMatch(updates[0].properties)
    }
}

@available(iOS 13.0, *)
extension AppcuesSubmitFormAction {
    convenience init?() {
        self.init(configuration: AppcuesExperiencePluginConfiguration(nil))
    }
    convenience init?(skipValidation: Bool) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(AppcuesSubmitFormAction.Config(skipValidation: skipValidation)))
    }
}
