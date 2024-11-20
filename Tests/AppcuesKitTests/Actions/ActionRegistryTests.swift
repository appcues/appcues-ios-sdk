//
//  ActionRegistryTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-01-20.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class ActionRegistryTests: XCTestCase {

    var appcues: MockAppcues!
    var actionRegistry: ActionRegistry!
    var logger: DebugLogger!

    override func setUpWithError() throws {
        appcues = MockAppcues()
        logger = DebugLogger(previousLogger: nil)
        appcues.config.logger = logger
        actionRegistry = ActionRegistry(container: appcues.container)
    }

    @MainActor
    func testRegister() async throws {
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
            renderContext: .modal,
            interactionType: "Button Tapped",
            viewDescription: "My Button")

        await fulfillment(of: [executionExpectation], timeout: 1)
    }

    @MainActor
    func testUnknownAction() async throws {
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
            renderContext: .modal,
            interactionType: "Button Tapped",
            viewDescription: "My Button")

        await fulfillment(of: [executionExpectation], timeout: 1)
    }

    @MainActor
    func testDuplicateTypeRegistrations() async throws {
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
        let successfullyRegisteredAction1 = actionRegistry.register(action: TestAction.self)
        let successfullyRegisteredAction2 = actionRegistry.register(action: TestAction2.self)

        // Assert
        XCTAssertTrue(successfullyRegisteredAction1)
        XCTAssertFalse(successfullyRegisteredAction2)
        actionRegistry.enqueue(
            actionModels: [actionModel],
            level: .step,
            renderContext: .modal,
            interactionType: "Button Tapped",
            viewDescription: "My Button")
        await fulfillment(of: [executionExpectation, executionExpectation2], timeout: 1)

        XCTAssertEqual(logger.log.count, 1)
        let log = try XCTUnwrap(logger.log.first)
        XCTAssertEqual(log.level, .error)
        XCTAssertEqual(log.message, "Action of type @test/action is already registered.")
    }

    @MainActor
    func testQueueExecution() async throws {
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
            renderContext: .modal,
            interactionType: "Button Tapped",
            viewDescription: "My Button")


        // Assert
        await fulfillment(of: [executionExpectation], timeout: 1)
    }

    @MainActor
    func testQueueAppendingWhileProcessing() async throws {
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
            renderContext: .modal,
            interactionType: "Button Tapped",
            viewDescription: "My Button")

        // Enqueue more while the delayed one is processing
        actionRegistry.enqueue(
            actionModels: [actionModel, actionModel, actionModel, actionModel],
            level: .step,
            renderContext: .modal,
            interactionType: "Button Tapped",
            viewDescription: "Another Button")

        // Assert
        await fulfillment(of: [executionExpectation], timeout: 2)
    }

    @MainActor
    func testQueueTransforming() async throws {
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
            renderContext: .modal,
            interactionType: "Button Tapped",
            viewDescription: "My Button")

        // Assert

        // The last two actionModel's should be removed
        await fulfillment(of: [executionExpectation], timeout: 1)
    }
}

private extension ActionRegistryTests {
    class TestAction: AppcuesExperienceAction, ExperienceActionQueueTransforming {
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

        required init?(configuration: AppcuesExperiencePluginConfiguration) {
            let config = configuration.decode(Config.self)
            executionExpectation = config?.executionExpectation?.expectation
            delay = config?.delay
            removeSubsequent = config?.removeSubsequent ?? false
        }

        func execute() async throws {
            if let delay = delay {
                try await Task.sleep(nanoseconds: UInt64(delay) * 1_000_000_000)
            }
            executionExpectation?.fulfill()
        }


        func transformQueue(_ queue: [AppcuesExperienceAction], index: Int, inContext appcues: Appcues) -> [AppcuesKit.AppcuesExperienceAction] {
            guard removeSubsequent else { return queue }
            return Array(queue[0...index])
        }
    }

    class TestAction2: AppcuesExperienceAction {
        static let type = "@test/action"

        var executionExpectation2: XCTestExpectation?

        required init?(configuration: AppcuesExperiencePluginConfiguration) {
            let config = configuration.decode(TestAction.Config.self)
            executionExpectation2 = config?.executionExpectation2?.expectation
        }

        func execute() async throws {
            executionExpectation2?.fulfill()
        }
    }
}

extension Experience.Action {
    init(trigger: String, type: String, config: Decodable?) {
        self.init(trigger: trigger, type: type, configDecoder: FakePluginDecoder(config))
    }
}
