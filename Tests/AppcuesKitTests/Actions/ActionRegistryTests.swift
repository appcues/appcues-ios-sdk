//
//  ActionRegistryTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-01-20.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

@available(iOS 13.0, *)
class ActionRegistryTests: XCTestCase {

    var appcues: MockAppcues!
    var actionRegistry: ActionRegistry!

    override func setUpWithError() throws {
        appcues = MockAppcues()
        actionRegistry = ActionRegistry(container: appcues.container)
    }

    func testRegister() throws {
        // Arrange
        let executionExpectation = expectation(description: "Action executed")
        let actionModel = Experience.Action(
            trigger: "tap",
            type: TestAction.type,
            config: ["executionExpectation": executionExpectation]
        )

        // Act
        actionRegistry.register(action: TestAction.self)

        // Assert
        actionRegistry.enqueue(actionModels: [actionModel])
        waitForExpectations(timeout: 1)
    }


    func testUnknownAction() throws {
        // Arrange
        let executionExpectation = expectation(description: "Action executed")
        executionExpectation.isInverted = true
        let actionModel = Experience.Action(
            trigger: "tap",
            type: "@unknown/action",
            config: ["executionExpectation": executionExpectation]
        )

        // Act
        actionRegistry.register(action: TestAction.self)

        // Assert
        actionRegistry.enqueue(actionModels: [actionModel])
        waitForExpectations(timeout: 1)

    }

    func testDuplicateTypeRegistrations() throws {
        // Arrange
        let executionExpectation = expectation(description: "Action executed")
        let executionExpectation2 = expectation(description: "Second action executed")
        executionExpectation2.isInverted = true
        let actionModel = Experience.Action(
            trigger: "tap",
            type: TestAction.type,
            config: [
                "executionExpectation": executionExpectation,
                "executionExpectation2": executionExpectation2
            ]
        )

        // Act
        actionRegistry.register(action: TestAction.self)
        // This will trigger an assertionFailure if we're not in a test cycle
        actionRegistry.register(action: TestAction2.self)

        // Assert
        actionRegistry.enqueue(actionModels: [actionModel])
        waitForExpectations(timeout: 1)
    }

    func testQueueExecution() throws {
        // Arrange
        let executionExpectation = expectation(description: "Action executed")
        executionExpectation.expectedFulfillmentCount = 5
        let actionModel = Experience.Action(
            trigger: "tap",
            type: TestAction.type,
            config: ["executionExpectation": executionExpectation]
        )
        actionRegistry.register(action: TestAction.self)

        // Act
        actionRegistry.enqueue(actionModels: [actionModel, actionModel, actionModel, actionModel, actionModel])

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testQueueAppendingWhileProcessing() throws {
        // Arrange
        let executionExpectation = expectation(description: "Action executed")
        executionExpectation.expectedFulfillmentCount = 5
        let actionModel = Experience.Action(
            trigger: "tap",
            type: TestAction.type,
            config: ["executionExpectation": executionExpectation]
        )
        let delayedActionModel = Experience.Action(
            trigger: "tap",
            type: TestAction.type,
            config: ["executionExpectation": executionExpectation, "delay": 1]
        )
        actionRegistry.register(action: TestAction.self)

        // Act
        actionRegistry.enqueue(actionModels: [delayedActionModel])
        // Enqueue more while the delayed one is processing
        actionRegistry.enqueue(actionModels: [actionModel, actionModel, actionModel, actionModel])

        // Assert
        waitForExpectations(timeout: 1)
    }

}

@available(iOS 13.0, *)
private extension ActionRegistryTests {
    class TestAction: ExperienceAction {
        static let type = "@test/action"

        let executionExpectation: XCTestExpectation?
        let delay: TimeInterval?

        required init?(config: [String: Any]?) {
            executionExpectation = config?["executionExpectation"] as? XCTestExpectation
            delay = config?["delay"] as? TimeInterval
        }

        func execute(inContext appcues: Appcues, completion: @escaping () -> Void) {
            if let delay = delay {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self.executionExpectation?.fulfill()
                    completion()
                }
            } else {
                executionExpectation?.fulfill()
                completion()
            }
        }
    }

    class TestAction2: ExperienceAction {
        static let type = "@test/action"

        var executionExpectation2: XCTestExpectation?

        required init?(config: [String: Any]?) {
            executionExpectation2 = config?["executionExpectation2"] as? XCTestExpectation
        }

        func execute(inContext appcues: Appcues, completion: @escaping () -> Void) {
            executionExpectation2?.fulfill()
            completion()
        }
    }
}
