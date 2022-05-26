//
//  AppcuesUpdateProfileActionTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-01-20.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

@available(iOS 13.0, *)
class AppcuesUpdateProfileActionTests: XCTestCase {

    var appcues: MockAppcues!

    override func setUpWithError() throws {
        appcues = MockAppcues()
    }

    func testInit() throws {
        // Act
        let action = AppcuesUpdateProfileAction(config: ["profile_attribute": "value"])
        let failedAction = AppcuesUpdateProfileAction(config: nil)

        // Assert
        XCTAssertEqual(AppcuesUpdateProfileAction.type, "@appcues/update-profile")
        XCTAssertNotNil(action)
        XCTAssertEqual(action?.properties["profile_attribute"] as? String, "value")
        XCTAssertNil(failedAction)
    }

    func testExecute() throws {
        // Arrange
        var completionCount = 0
        var identifyCount = 0
        appcues.onIdentify = { userID, properties in
            XCTAssertEqual(userID, "user-id")
            XCTAssertEqual(properties?.count, 1)
            XCTAssertEqual(properties?["profile_attribute"] as? String, "value")

            identifyCount += 1
        }
        let action = AppcuesUpdateProfileAction(config: ["profile_attribute": "value"])

        // Act
        action?.execute(inContext: appcues, completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(identifyCount, 1)
    }
}
