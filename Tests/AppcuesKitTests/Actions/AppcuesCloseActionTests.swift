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
        let action = AppcuesCloseAction(configuration: AppcuesExperiencePluginConfiguration(nil, appcues: appcues))

        // Assert
        XCTAssertEqual(AppcuesCloseAction.type, "@appcues/close")
        XCTAssertNotNil(action)
    }

    func testExecute() throws {
        // Arrange
        var completionCount = 0
        var dismissCount = 0
        appcues.experienceRenderer.onDismiss = { _, markComplete, completion in
            XCTAssertFalse(markComplete)
            dismissCount += 1
            completion?(.success(()))
        }
        let action = AppcuesCloseAction(appcues: appcues)

        // Act
        action?.execute(completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(dismissCount, 1)
    }

    func testExecuteMarkComplete() throws {
        // Arrange
        var completionCount = 0
        var dismissCount = 0
        appcues.experienceRenderer.onDismiss = { _, markComplete, completion in
            XCTAssertTrue(markComplete)
            dismissCount += 1
            completion?(.success(()))
        }
        let action = AppcuesCloseAction(appcues: appcues, markComplete: true)

        // Act
        action?.execute(completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(dismissCount, 1)
    }

    func testExecuteCompletesWithoutAppcuesInstance() throws {
        // Arrange
        var completionCount = 0
        let action = try XCTUnwrap(AppcuesCloseAction(appcues: nil))

        // Act
        action.execute(completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
    }
}

@available(iOS 13.0, *)
extension AppcuesCloseAction {
    convenience init?(appcues: Appcues?) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(nil, appcues: appcues))
    }
    convenience init?(appcues: Appcues?, markComplete: Bool) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(AppcuesCloseAction.Config(markComplete: markComplete), appcues: appcues))
    }
}
