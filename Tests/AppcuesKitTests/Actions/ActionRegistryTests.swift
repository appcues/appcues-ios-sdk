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
        let actionClosures = actionRegistry.actionClosures(for: [actionModel])
        XCTAssertEqual(actionClosures.count, 1)

        actionClosures[0]()
        waitForExpectations(timeout: 1)
    }


    func testUnknownAction() throws {
        // Arrange
        let actionModel = Experience.Action(
            trigger: "tap",
            type: "@unknown/action",
            config: nil
        )

        // Act
        actionRegistry.register(action: TestAction.self)

        // Assert
        let actionClosures = actionRegistry.actionClosures(for: [actionModel])
        XCTAssertEqual(actionClosures.count, 0)
    }

    /// Codifies the behavior that if there are multiple actions with the same `type`, then only the one registered earliest **that can be successfully initialized** is executed.
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
        actionRegistry.register(action: ImpossibleAction.self)
        actionRegistry.register(action: TestAction.self)
        actionRegistry.register(action: TestAction2.self)

        // Assert
        let actionClosures = actionRegistry.actionClosures(for: [actionModel])
        XCTAssertEqual(actionClosures.count, 1)

        actionClosures[0]()
        waitForExpectations(timeout: 1)
    }
}

extension ActionRegistryTests {
    internal struct TestAction: ExperienceAction {
        static let type = "@test/action"

        var executionExpectation: XCTestExpectation?

        init?(config: [String: Any]?) {
            executionExpectation = config?["executionExpectation"] as? XCTestExpectation
        }

        func execute(inContext appcues: Appcues) {
            executionExpectation?.fulfill()
        }
    }

    internal struct TestAction2: ExperienceAction {
        static let type = "@test/action"

        var executionExpectation2: XCTestExpectation?

        init?(config: [String: Any]?) {
            executionExpectation2 = config?["executionExpectation2"] as? XCTestExpectation
        }

        func execute(inContext appcues: Appcues) {
            executionExpectation2?.fulfill()
        }
    }

    internal struct ImpossibleAction: ExperienceAction {
        static let type = "@test/action"

        init?(config: [String: Any]?) {
            // Always fail initialization
            return nil
        }

        func execute(inContext appcues: Appcues) {
        }
    }

}
