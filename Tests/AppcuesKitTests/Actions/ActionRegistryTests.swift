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
            config: TestAction.Config(expectation: executionExpectation)
        )

        // Act
        actionRegistry.register(action: TestAction.self)

        // Assert
        actionRegistry.enqueue(
            actionModels: [actionModel],
            level: .step,
            interactionType: "Button Tapped",
            viewDescription: "My Button")
        waitForExpectations(timeout: 1)
    }

    func testUnknownAction() throws {
        // Arrange
        let executionExpectation = expectation(description: "Action executed")
        executionExpectation.isInverted = true
        let actionModel = Experience.Action(
            trigger: "tap",
            type: "@unknown/action",
            config: TestAction.Config(expectation: executionExpectation)
        )

        // Act
        actionRegistry.register(action: TestAction.self)

        // Assert
        actionRegistry.enqueue(
            actionModels: [actionModel],
            level: .step,
            interactionType: "Button Tapped",
            viewDescription: "My Button")
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
            config: TestAction.Config(expectation: executionExpectation, expectation2: executionExpectation2)
        )

        // Act
        actionRegistry.register(action: TestAction.self)
        // This will trigger an assertionFailure if we're not in a test cycle
        actionRegistry.register(action: TestAction2.self)

        // Assert
        actionRegistry.enqueue(
            actionModels: [actionModel],
            level: .step,
            interactionType: "Button Tapped",
            viewDescription: "My Button")
        waitForExpectations(timeout: 1)
    }

    func testQueueExecution() throws {
        // Arrange
        let executionExpectation = expectation(description: "Action executed")
        executionExpectation.expectedFulfillmentCount = 5
        let actionModel = Experience.Action(
            trigger: "tap",
            type: TestAction.type,
            config: TestAction.Config(expectation: executionExpectation)
        )
        actionRegistry.register(action: TestAction.self)

        // Act
        actionRegistry.enqueue(
            actionModels: [actionModel, actionModel, actionModel, actionModel, actionModel],
            level: .step,
            interactionType: "Button Tapped",
            viewDescription: "My Button")


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
            config: TestAction.Config(expectation: executionExpectation)
        )
        let delayedActionModel = Experience.Action(
            trigger: "tap",
            type: TestAction.type,
            config: TestAction.Config(expectation: executionExpectation, delay: 1.0)
        )
        actionRegistry.register(action: TestAction.self)

        // Act
        actionRegistry.enqueue(
            actionModels: [delayedActionModel],
            level: .step,
            interactionType: "Button Tapped",
            viewDescription: "My Button")

        // Enqueue more while the delayed one is processing
        actionRegistry.enqueue(
            actionModels: [actionModel, actionModel, actionModel, actionModel],
            level: .step,
            interactionType: "Button Tapped",
            viewDescription: "Another Button")

        // Assert
        waitForExpectations(timeout: 2)
    }

    func testQueueTransforming() throws {
        // Arrange
        let executionExpectation = expectation(description: "Action executed")
        executionExpectation.expectedFulfillmentCount = 3
        let actionModel = Experience.Action(
            trigger: "tap",
            type: TestAction.type,
            config: TestAction.Config(expectation: executionExpectation)
        )
        let actionModel2 = Experience.Action(
            trigger: "tap",
            type: TestAction.type,
            config: TestAction.Config(expectation: executionExpectation, removeSubsequent: true)
        )
        actionRegistry.register(action: TestAction.self)

        // Act
        actionRegistry.enqueue(
            actionModels: [actionModel, actionModel, actionModel2, actionModel, actionModel],
            level: .step,
            interactionType: "Button Tapped",
            viewDescription: "My Button")

        // Assert

        // The last two actionModel's should be removed
        waitForExpectations(timeout: 1)
    }
}

@available(iOS 13.0, *)
private extension ActionRegistryTests {
    class TestAction: ExperienceAction, ExperienceActionQueueTransforming {
        struct Config: Decodable {
            let executionExpectation: DecodableExpectation?
            let executionExpectation2: DecodableExpectation?
            let delay: TimeInterval?
            let removeSubsequent: Bool?

            init(expectation: XCTestExpectation? = nil,
                 expectation2: XCTestExpectation? = nil,
                 delay: TimeInterval? = nil,
                 removeSubsequent: Bool? = nil) {
                self.delay = delay
                self.removeSubsequent = removeSubsequent
                self.executionExpectation = DecodableExpectation(expectation: expectation)
                self.executionExpectation2 = DecodableExpectation(expectation: expectation2)
            }
        }

        static let type = "@test/action"

        let executionExpectation: XCTestExpectation?
        let delay: TimeInterval?
        let removeSubsequent: Bool

        required init?(configuration: ExperiencePluginConfiguration) {
            let config = configuration.decode(Config.self)
            executionExpectation = config?.executionExpectation?.expectation
            delay = config?.delay
            removeSubsequent = config?.removeSubsequent ?? false
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

        func transformQueue(_ queue: [ExperienceAction], index: Int, inContext appcues: Appcues) -> [ExperienceAction] {
            guard removeSubsequent else { return queue }
            return Array(queue[0...index])
        }
    }

    class TestAction2: ExperienceAction {
        static let type = "@test/action"

        var executionExpectation2: XCTestExpectation?

        required init?(configuration: ExperiencePluginConfiguration) {
            let config = configuration.decode(TestAction.Config.self)
            executionExpectation2 = config?.executionExpectation2?.expectation
        }

        func execute(inContext appcues: Appcues, completion: @escaping () -> Void) {
            executionExpectation2?.fulfill()
            completion()
        }
    }
}

extension Experience.Action {
    init(trigger: String, type: String, config: Decodable?) {
        self.init(trigger: trigger, type: type, configDecoder: FakePluginDecoder(config))
    }
}
