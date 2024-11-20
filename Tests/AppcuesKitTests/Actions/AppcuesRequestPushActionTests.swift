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

    func testExecute() throws {
        // Arrange
        var refreshCount = 0
        var completionCount = 0
        let action = AppcuesRequestPushAction(appcues: appcues)

        appcues.pushMonitor.onRefreshPushStatus = {
            refreshCount += 1
        }

        // Act
        action?.execute(completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(refreshCount, 1)
        XCTAssertEqual(completionCount, 1)
    }

    func testExecuteCompletesWithoutAppcuesInstance() throws {
        // Arrange
        var completionCount = 0
        let action = try XCTUnwrap(AppcuesRequestPushAction(appcues: nil))

        // Act
        action.execute(completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
    }
}

extension AppcuesRequestPushAction {
    convenience init?(appcues: Appcues?) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(nil, appcues: appcues))
    }
}
