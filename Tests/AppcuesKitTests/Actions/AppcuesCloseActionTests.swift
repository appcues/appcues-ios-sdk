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
        var dismissCalled = false
        var completionCalled = false
        appcues.experienceRenderer.onDismissCurrentExperience = {
            dismissCalled = true
        }
        let action = AppcuesCloseAction(config: nil)

        // Act
        action?.execute(inContext: appcues) {
            completionCalled = true
        }

        // Assert
        XCTAssertTrue(dismissCalled)
        XCTAssertTrue(completionCalled)
    }
}
