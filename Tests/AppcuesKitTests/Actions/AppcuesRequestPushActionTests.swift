//
//  AppcuesRequestPushActionTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2024-02-27.
//  Copyright © 2024 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class AppcuesRequestPushActionTests: XCTestCase {

    var appcues: MockAppcues!

    override func setUpWithError() throws {
        appcues = MockAppcues()
    }

    func testInit() throws {
        // Act
        let action = AppcuesRequestPushAction(configuration: AppcuesExperiencePluginConfiguration(nil, appcues: appcues))

        // Assert
        XCTAssertEqual(AppcuesRequestPushAction.type, "@appcues/request-push")
        XCTAssertNotNil(action)
    }

    func testExecute() async throws {
        // Arrange
        var refreshCount = 0
        let action = AppcuesRequestPushAction(appcues: appcues)

        appcues.pushMonitor.onRefreshPushStatus = {
            refreshCount += 1
            return .authorized
        }

        // Act
        try await action?.execute()

        // Assert
        XCTAssertEqual(refreshCount, 1)
    }

    func testExecuteThrowsWithoutAppcuesInstance() async throws {
        // Arrange
        let action = try XCTUnwrap(AppcuesRequestPushAction(appcues: nil))

        // Act/Assert
        await XCTAssertThrowsAsyncError(try await action.execute()) {
            XCTAssertEqual(($0 as? AppcuesTraitError)?.description, "No appcues instance")
        }
    }
}

extension AppcuesRequestPushAction {
    convenience init?(appcues: Appcues?) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(nil, appcues: appcues))
    }
}
