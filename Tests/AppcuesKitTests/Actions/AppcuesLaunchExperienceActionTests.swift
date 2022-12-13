//
//  AppcuesLaunchExperienceActionTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-01-20.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

@available(iOS 13.0, *)
class AppcuesLaunchExperienceActionTests: XCTestCase {

    var appcues: MockAppcues!

    override func setUpWithError() throws {
        appcues = MockAppcues()
        appcues.sessionID = UUID()
    }

    func testInit() throws {
        // Act
        let action = AppcuesLaunchExperienceAction(config: DecodingExperienceConfig(["experienceID": "123"]))
        let failedAction = AppcuesLaunchExperienceAction(config: DecodingExperienceConfig([:]))

        // Assert
        XCTAssertEqual(AppcuesLaunchExperienceAction.type, "@appcues/launch-experience")
        XCTAssertNotNil(action)
        XCTAssertEqual(action?.experienceID, "123")
        XCTAssertNil(failedAction)
    }

    func testExecute() throws {
        // Arrange
        var completionCount = 0
        var loadCount = 0
        appcues.experienceLoader.onLoad = { contentID, published, completion in
            XCTAssertEqual(contentID, "123")
            loadCount += 1
            completion?(.success(()))
        }
        let action = AppcuesLaunchExperienceAction(config: DecodingExperienceConfig(["experienceID": "123"]))

        // Act
        action?.execute(inContext: appcues, completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(loadCount, 1)
    }

    func testExecuteWhenLoadFails() throws {
        // Arrange
        var completionCount = 0
        var loadCount = 0
        appcues.experienceLoader.onLoad = { contentID, published, completion in
            XCTAssertEqual(contentID, "123")
            loadCount += 1
            completion?(.failure(AppcuesError.noActiveSession))
        }
        let action = AppcuesLaunchExperienceAction(config: DecodingExperienceConfig(["experienceID": "123"]))

        // Act
        action?.execute(inContext: appcues, completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(loadCount, 1)
    }

}
