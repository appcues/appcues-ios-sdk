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
        let action = AppcuesCloseAction(config: nil)

        // Assert
        XCTAssertEqual(AppcuesCloseAction.type, "@appcues/close")
        XCTAssertNotNil(action)
    }

    func testExecute() throws {
        // Arrange
        var completionCount = 0
        var dismissCount = 0
        appcues.experienceRenderer.onDismissCurrentExperience = { completion in
            dismissCount += 1
            completion?()
        }
        let action = AppcuesCloseAction(config: nil)

        // Act
        action?.execute(inContext: appcues, completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(dismissCount, 1)
    }
}
