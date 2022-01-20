//
//  AppcuesLaunchExperienceActionTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-01-20.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class AppcuesLaunchExperienceActionTests: XCTestCase {

    var appcues: MockAppcues!

    override func setUpWithError() throws {
        appcues = MockAppcues()
    }

    func testInit() throws {
        // Act
        let action = AppcuesLaunchExperienceAction(config: ["experienceID": "123"])
        let failedAction = AppcuesLaunchExperienceAction(config: [:])

        // Assert
        XCTAssertEqual(AppcuesLaunchExperienceAction.type, "@appcues/launch-experience")
        XCTAssertNotNil(action)
        XCTAssertEqual(action?.experienceID, "123")
        XCTAssertNil(failedAction)
    }

    func testExecute() throws {
        // Arrange
        var loadCalled = false
        appcues.experienceLoader.onLoad = { contentID in
            XCTAssertEqual(contentID, "123")
            loadCalled = true
        }
        let action = AppcuesLaunchExperienceAction(config: ["experienceID": "123"])

        // Act
        action?.execute(inContext: appcues)

        // Assert
        XCTAssertTrue(loadCalled)
    }
}
