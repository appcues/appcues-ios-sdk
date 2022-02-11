//
//  AppcuesContinueActionTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-01-20.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class AppcuesContinueActionTests: XCTestCase {

    var appcues: MockAppcues!

    override func setUpWithError() throws {
        appcues = MockAppcues()
    }

    func testInit() throws {
        // Act
        let indexAction = AppcuesContinueAction(config: ["index": 1])
        let offsetAction = AppcuesContinueAction(config: ["offset": -1])
        let stepIDAction = AppcuesContinueAction(config: ["stepID": "8ebcb374-0eff-45a5-9d62-ffee52d8a57b"])
        let defaultAction = AppcuesContinueAction(config: nil)


        // Assert
        XCTAssertEqual(AppcuesContinueAction.type, "@appcues/continue")
        XCTAssertNotNil(indexAction)
        XCTAssertNotNil(offsetAction)
        XCTAssertNotNil(stepIDAction)
        XCTAssertNotNil(defaultAction)

        guard case .index(1) = indexAction?.stepReference else { return XCTFail() }
        guard case .offset(-1) = offsetAction?.stepReference else { return XCTFail() }
        guard case .stepID(UUID(uuidString: "8ebcb374-0eff-45a5-9d62-ffee52d8a57b")!) = stepIDAction?.stepReference else { return XCTFail() }
        guard case .offset(1) = defaultAction?.stepReference else { return XCTFail() }
    }

    func testExecute() throws {
        // Arrange
        var showStepCalled = false
        var completionCalled = false
        appcues.experienceRenderer.onShowStep = { stepRef in
            if case .offset(1) = stepRef {
                showStepCalled = true
            }
        }
        let action = AppcuesContinueAction(config: nil)

        // Act
        action?.execute(inContext: appcues) {
            completionCalled = true
        }

        // Assert
        XCTAssertTrue(showStepCalled)
        XCTAssertTrue(completionCalled)
    }
}
