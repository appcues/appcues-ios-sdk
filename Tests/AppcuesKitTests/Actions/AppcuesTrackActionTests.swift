//
//  AppcuesTrackActionTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-01-20.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

@available(iOS 13.0, *)
class AppcuesTrackActionTests: XCTestCase {

    var appcues: MockAppcues!

    override func setUpWithError() throws {
        appcues = MockAppcues()
    }

    func testInit() throws {
        // Act
        let action = AppcuesTrackAction(appcues: appcues, eventName: "My Custom Event")
        let failedAction = AppcuesTrackAction(configuration: AppcuesExperiencePluginConfiguration(nil, appcues: appcues))

        // Assert
        XCTAssertEqual(AppcuesTrackAction.type, "@appcues/track")
        XCTAssertNotNil(action)
        XCTAssertEqual(action?.eventName, "My Custom Event")
        XCTAssertNil(failedAction)
    }

    func testExecute() throws {
        // Arrange
        var completionCount = 0
        var trackCount = 0
        appcues.analyticsPublisher.onPublish = { trackingUpdate in
            XCTAssertEqual(trackingUpdate.type, .event(name: "My Custom Event", interactive: true))
            XCTAssertNil(trackingUpdate.properties)
            trackCount += 1
        }
        let action = AppcuesTrackAction(appcues: appcues, eventName: "My Custom Event")

        // Act
        action?.execute(completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(trackCount, 1)
    }
}

@available(iOS 13.0, *)
extension AppcuesTrackAction {
    convenience init?(appcues: Appcues) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(nil, appcues: appcues))
    }
    convenience init?(appcues: Appcues, eventName: String) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(AppcuesTrackAction.Config(eventName: eventName), appcues: appcues))
    }
}
