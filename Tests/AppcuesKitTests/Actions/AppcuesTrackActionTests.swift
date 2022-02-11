//
//  AppcuesTrackActionTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-01-20.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class AppcuesTrackActionTests: XCTestCase {

    var appcues: MockAppcues!

    override func setUpWithError() throws {
        appcues = MockAppcues()
    }

    func testInit() throws {
        // Act
        let action = AppcuesTrackAction(config: ["eventName": "My Custom Event"])
        let failedAction = AppcuesTrackAction(config: [:])

        // Assert
        XCTAssertEqual(AppcuesTrackAction.type, "@appcues/track")
        XCTAssertNotNil(action)
        XCTAssertEqual(action?.eventName, "My Custom Event")
        XCTAssertNil(failedAction)
    }

    func testExecute() throws {
        // Arrange
        var trackCalled = false
        var completionCalled = false
        appcues.onTrack = { name, properties in
            XCTAssertEqual(name, "My Custom Event")
            XCTAssertNil(properties)
            trackCalled = true
        }
        let action = AppcuesTrackAction(config: ["eventName": "My Custom Event"])

        // Act
        action?.execute(inContext: appcues) {
            completionCalled = true
        }

        // Assert
        XCTAssertTrue(trackCalled)
        XCTAssertTrue(completionCalled)
    }
}
