//
//  AppcuesCloseActionTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-01-20.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class AppcuesCloseActionTests: XCTestCase {

    var appcues: MockAppcues!

    override func setUpWithError() throws {
        appcues = MockAppcues()
    }

    func testInit() throws {
        // Act
        let action = AppcuesCloseAction(configuration: AppcuesExperiencePluginConfiguration(nil, appcues: appcues))
        let directInitAction = AppcuesCloseAction(appcues: appcues, renderContext: .modal, markComplete: true)

        // Assert
        XCTAssertEqual(AppcuesCloseAction.type, "@appcues/close")
        XCTAssertNotNil(action)
        XCTAssertNotNil(directInitAction)
    }

    func testExecute() async throws {
        // Arrange
        var dismissCount = 0
        appcues.experienceRenderer.onDismiss = { _, markComplete in
            XCTAssertFalse(markComplete)
            dismissCount += 1
        }
        let action = AppcuesCloseAction(appcues: appcues)

        // Act
        try await action?.execute()

        // Assert
        XCTAssertEqual(dismissCount, 1)
    }

    func testExecuteMarkComplete() async throws {
        // Arrange
        var dismissCount = 0
        appcues.experienceRenderer.onDismiss = { _, markComplete in
            XCTAssertTrue(markComplete)
            dismissCount += 1
        }
        let action = AppcuesCloseAction(appcues: appcues, markComplete: true)

        // Act
        try await action?.execute()

        // Assert
        XCTAssertEqual(dismissCount, 1)
    }

    func testExecuteThrowsWithoutAppcuesInstance() async throws {
        // Arrange
        let action = try XCTUnwrap(AppcuesCloseAction(appcues: nil))

        // Act/Assert
        await XCTAssertThrowsAsyncError(try await action.execute()) {
            XCTAssertEqual(($0 as? AppcuesTraitError)?.description, "No appcues instance")
        }
    }
}

extension AppcuesCloseAction {
    convenience init?(appcues: Appcues?) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(nil, appcues: appcues))
    }
    convenience init?(appcues: Appcues?, markComplete: Bool) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(AppcuesCloseAction.Config(markComplete: markComplete), appcues: appcues))
    }
}
