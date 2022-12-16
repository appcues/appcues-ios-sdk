//
//  AppcuesCloseActionTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-01-20.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

@available(iOS 13.0, *)
class AppcuesCloseActionTests: XCTestCase {

    var appcues: MockAppcues!

    override func setUpWithError() throws {
        appcues = MockAppcues()
    }

    func testInit() throws {
        // Act
        let action = AppcuesCloseAction()

        // Assert
        XCTAssertEqual(AppcuesCloseAction.type, "@appcues/close")
        XCTAssertNotNil(action)
    }

    func testExecute() throws {
        // Arrange
        var completionCount = 0
        var dismissCount = 0
        appcues.experienceRenderer.onDismissCurrentExperience = { markComplete, completion in
            XCTAssertFalse(markComplete)
            dismissCount += 1
            completion?(.success(()))
        }
        let action = AppcuesCloseAction()

        // Act
        action?.execute(inContext: appcues, completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(dismissCount, 1)
    }

    func testExecuteMarkComplete() throws {
        // Arrange
        var completionCount = 0
        var dismissCount = 0
        appcues.experienceRenderer.onDismissCurrentExperience = { markComplete, completion in
            XCTAssertTrue(markComplete)
            dismissCount += 1
            completion?(.success(()))
        }
        let action = AppcuesCloseAction(markComplete: true)

        // Act
        action?.execute(inContext: appcues, completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(dismissCount, 1)
    }
}

extension AppcuesCloseAction {
    convenience init?() {
        self.init(configuration: ExperiencePluginConfiguration(nil))
    }
    convenience init?(markComplete: Bool) {
        self.init(configuration: ExperiencePluginConfiguration(AppcuesCloseAction.Config(markComplete: markComplete)))
    }
}
