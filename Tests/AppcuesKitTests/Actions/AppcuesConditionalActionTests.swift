//
//  AppcuesConditionalActionTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2025-08-21.
//  Copyright © 2025 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

@available(iOS 13.0, *)
class AppcuesConditionalActionTests: XCTestCase {

    var appcues: MockAppcues!

    override func setUpWithError() throws {
        appcues = MockAppcues()
    }

    func testInit() throws {
        // Act
        let action = AppcuesConditionalAction(configuration: AppcuesExperiencePluginConfiguration(
            AppcuesConditionalAction.Config(checks: []), appcues: appcues))
        let failedAction = AppcuesConditionalAction(configuration: AppcuesExperiencePluginConfiguration(
            nil, appcues: appcues))

        // Assert
        XCTAssertEqual(AppcuesConditionalAction.type, "@appcues/conditional")
        XCTAssertNotNil(action)
        XCTAssertNil(failedAction)
    }

    func testExecute() {
        // Arrange
        var completionCount = 0
        let action = AppcuesConditionalAction(appcues: appcues, checks: [])

        // Act
        action?.execute(completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
    }

    func testTransformQueueNoFormState() throws {
        // Arrange
        appcues.experienceRenderer.onExperienceData = { _ in
            nil // No experience data, so no form state
        }

        let action0 = try XCTUnwrap(AppcuesTrackAction(appcues: appcues, eventName: "Before"))
        let action = try XCTUnwrap(AppcuesConditionalAction(appcues: appcues, checks: []))
        let action1 = try XCTUnwrap(AppcuesTrackAction(appcues: appcues, eventName: "After"))
        let initialQueue: [AppcuesExperienceAction] = [action0, action, action1]

        // Act
        let updatedQueue = action.transformQueue(initialQueue, index: 1, inContext: appcues)

        // Assert
        XCTAssertEqual(updatedQueue.count, 3, "Queue should remain unchanged when no form state")
        XCTAssertTrue(updatedQueue[0] === action0)
        XCTAssertTrue(updatedQueue[1] === action)
        XCTAssertTrue(updatedQueue[2] === action1)
    }

    func testTransformQueueNoChecksSatisfied() throws {
        // Arrange
        let blockID = ExperienceComponent.TextInputModel.mockId
        appcues.experienceRenderer.onExperienceData = { _ in
            ExperienceData.mockWithForm(defaultValue: "no")
        }

        let check = AppcuesConditionalAction.Check(
            condition: .survey(Clause.SurveyClause(block: blockID, operator: .equals, value: "yes")),
            actions: []
        )
        
        let action0 = try XCTUnwrap(AppcuesTrackAction(appcues: appcues, eventName: "Before"))
        let action1 = try XCTUnwrap(AppcuesConditionalAction(appcues: appcues, checks: [check]))
        let action2 = try XCTUnwrap(AppcuesTrackAction(appcues: appcues, eventName: "After"))
        let initialQueue: [AppcuesExperienceAction] = [action0, action1, action2]

        // Act
        let updatedQueue = action1.transformQueue(initialQueue, index: 1, inContext: appcues)

        // Assert
        XCTAssertEqual(updatedQueue.count, 3, "Queue should remain unchanged when no checks are satisfied")
        XCTAssertTrue(updatedQueue[safe: 0] === action0)
        XCTAssertTrue(updatedQueue[safe: 1] === action1)
        XCTAssertTrue(updatedQueue[safe: 2] === action2)
    }

    func testTransformQueueFirstCheckSatisfied() throws {
        // Arrange
        let blockID = ExperienceComponent.TextInputModel.mockId
        appcues.experienceRenderer.onExperienceData = { _ in
            ExperienceData.mockWithForm(defaultValue: "yes")
        }

        let checks = [
            AppcuesConditionalAction.Check(
                condition: .survey(Clause.SurveyClause(block: blockID, operator: .equals, value: "yes")),
                actions: [
                    Experience.Action(
                        trigger: "tap",
                        type: "@appcues/track",
                        config: AppcuesTrackAction.Config(eventName: "Replacement", attributes: nil)
                    ),
                    Experience.Action(
                        trigger: "tap",
                        type: "@appcues/continue",
                        config: AppcuesContinueAction.Config(index: nil, offset: nil, stepID: UUID())
                    )
                ]
            ),
            // This 2nd check should be ignored because the first is satisfied
            AppcuesConditionalAction.Check(
                condition: .survey(Clause.SurveyClause(block: blockID, operator: .startsWith, value: "y")),
                actions: [
                    Experience.Action(
                        trigger: "tap",
                        type: "@appcues/close",
                        config: AppcuesCloseAction.Config(markComplete: true)
                    )
                ]
            )

        ]

        let action0 = try XCTUnwrap(AppcuesTrackAction(appcues: appcues, eventName: "Before"))
        let action1 = try XCTUnwrap(AppcuesConditionalAction(appcues: appcues, checks: checks))
        let action2 = try XCTUnwrap(AppcuesTrackAction(appcues: appcues, eventName: "After"))
        let initialQueue: [AppcuesExperienceAction] = [action0, action1, action2]

        // Act
        let updatedQueue = action1.transformQueue(initialQueue, index: 1, inContext: appcues)

        // Assert
        XCTAssertEqual(updatedQueue.count, 4, "Queue should have two new items to replace the one")
        XCTAssertTrue(updatedQueue[safe: 0] === action0, "First action should remain")
        XCTAssertTrue(updatedQueue[safe: 1] is AppcuesTrackAction, "Conditional action should be replaced with track action")
        XCTAssertTrue(updatedQueue[safe: 2] is AppcuesContinueAction, "Conditional action should be replaced with continue action")
        XCTAssertTrue(updatedQueue[safe: 3] === action2, "Last action should remain")
    }

    func testTransformQueueSecondCheckSatisfied() throws {
        // Arrange
        let blockID = ExperienceComponent.TextInputModel.mockId
        appcues.experienceRenderer.onExperienceData = { _ in
            ExperienceData.mockWithForm(defaultValue: "maybe")
        }

        let checks = [
            AppcuesConditionalAction.Check(
                condition: .survey(Clause.SurveyClause(block: blockID, operator: .equals, value: "yes")),
                actions: [
                    Experience.Action(
                        trigger: "tap",
                        type: "@appcues/track",
                        config: AppcuesTrackAction.Config(eventName: "First", attributes: nil)
                    )
                ]
            ),
            AppcuesConditionalAction.Check(
                condition: .survey(Clause.SurveyClause(block: blockID, operator: .equals, value: "maybe")),
                actions: [
                    Experience.Action(
                        trigger: "tap",
                        type: "@appcues/close",
                        config: AppcuesCloseAction.Config(markComplete: true)
                    )
                ]
            )
        ]

        let action0 = try XCTUnwrap(AppcuesTrackAction(appcues: appcues, eventName: "Before"))
        let action1 = try XCTUnwrap(AppcuesConditionalAction(appcues: appcues, checks: checks))
        let action2 = try XCTUnwrap(AppcuesTrackAction(appcues: appcues, eventName: "After"))
        let initialQueue: [AppcuesExperienceAction] = [action0, action1, action2]

        // Act
        let updatedQueue = action1.transformQueue(initialQueue, index: 1, inContext: appcues)

        // Assert
        XCTAssertEqual(updatedQueue.count, 3, "Queue should have same count but conditional replaced")
        XCTAssertTrue(updatedQueue[safe: 0] === action0, "First action should remain")
        XCTAssertTrue(updatedQueue[safe: 1] is AppcuesCloseAction, "Conditional action should be replaced with close action")
        XCTAssertTrue(updatedQueue[safe: 2] === action2, "Last action should remain")
    }

    func testTransformQueueElseCheckSatisfied() throws {
        // Arrange
        let blockID = ExperienceComponent.TextInputModel.mockId
        appcues.experienceRenderer.onExperienceData = { _ in
            ExperienceData.mockWithForm(defaultValue: "no")
        }

        let checks = [
            AppcuesConditionalAction.Check(
                condition: .survey(Clause.SurveyClause(block: blockID, operator: .equals, value: "yes")),
                actions: [
                    Experience.Action(
                        trigger: "tap",
                        type: "@appcues/track",
                        config: AppcuesTrackAction.Config(eventName: "First", attributes: nil)
                    )
                ]
            ),
            AppcuesConditionalAction.Check(
                condition: nil, // else clause
                actions: [
                    Experience.Action(
                        trigger: "tap",
                        type: "@appcues/close",
                        config: AppcuesCloseAction.Config(markComplete: true)
                    )
                ]
            )
        ]
        
        let action0 = try XCTUnwrap(AppcuesTrackAction(appcues: appcues, eventName: "Before"))
        let action1 = try XCTUnwrap(AppcuesConditionalAction(appcues: appcues, checks: checks))
        let action2 = try XCTUnwrap(AppcuesTrackAction(appcues: appcues, eventName: "After"))
        let initialQueue: [AppcuesExperienceAction] = [action0, action1, action2]

        // Act
        let updatedQueue = action1.transformQueue(initialQueue, index: 1, inContext: appcues)

        // Assert
        XCTAssertEqual(updatedQueue.count, 3, "Queue should have same count but conditional replaced")
        XCTAssertTrue(updatedQueue[safe: 0] === action0, "First action should remain")
        XCTAssertTrue(updatedQueue[safe: 1] is AppcuesCloseAction, "Conditional action should be replaced with close action")
        XCTAssertTrue(updatedQueue[safe: 2] === action2, "Last action should remain")
    }

    func testTransformQueueEmptyActionsArray() throws {
        // Arrange
        let blockID = ExperienceComponent.TextInputModel.mockId
        appcues.experienceRenderer.onExperienceData = { _ in
            ExperienceData.mockWithForm(defaultValue: "yes")
        }

        let check = AppcuesConditionalAction.Check(
            condition: .survey(Clause.SurveyClause(block: blockID, operator: .equals, value: "yes")),
            actions: []
        )
        
        let action0 = try XCTUnwrap(AppcuesTrackAction(appcues: appcues, eventName: "Before"))
        let action1 = try XCTUnwrap(AppcuesConditionalAction(appcues: appcues, checks: [check]))
        let action2 = try XCTUnwrap(AppcuesTrackAction(appcues: appcues, eventName: "After"))
        let initialQueue: [AppcuesExperienceAction] = [action0, action1, action2]

        // Act
        let updatedQueue = action1.transformQueue(initialQueue, index: 1, inContext: appcues)

        // Assert
        XCTAssertEqual(updatedQueue.count, 2, "Queue should have 3 original - 1 conditional = 2 actions")
        XCTAssertTrue(updatedQueue[safe: 0] === action0, "First action should remain")
        XCTAssertTrue(updatedQueue[safe: 1] === action2, "Last action should remain")
    }
}

@available(iOS 13.0, *)
extension AppcuesConditionalAction {
    convenience init?(appcues: Appcues?) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(nil, appcues: appcues))
    }
    convenience init?(appcues: Appcues?, checks: [AppcuesConditionalAction.Check]) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(AppcuesConditionalAction.Config(checks: checks), appcues: appcues))
    }
}
