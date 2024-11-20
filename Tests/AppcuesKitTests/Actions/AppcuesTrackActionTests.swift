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
        let action = AppcuesTrackAction(fromDecoderWith: appcues, eventName: "My Custom Event")
        let directInitAction = AppcuesTrackAction(appcues: appcues, eventName: "My Custom Event")
        let failedAction = AppcuesTrackAction(configuration: AppcuesExperiencePluginConfiguration(nil, appcues: appcues))

        // Assert
        XCTAssertEqual(AppcuesTrackAction.type, "@appcues/track")
        XCTAssertNotNil(action)
        XCTAssertEqual(action?.eventName, "My Custom Event")
        XCTAssertNotNil(directInitAction)
        XCTAssertNil(failedAction)
    }

    func testExecute() async throws {
        // Arrange
        var trackCount = 0
        appcues.analyticsPublisher.onPublish = { trackingUpdate in
            XCTAssertEqual(trackingUpdate.type, .event(name: "My Custom Event", interactive: true))
            XCTAssertNil(trackingUpdate.properties)
            trackCount += 1
        }
        let action = AppcuesTrackAction(fromDecoderWith: appcues, eventName: "My Custom Event")

        // Act
        try await action?.execute()

        // Assert
        XCTAssertEqual(trackCount, 1)
    }
    
    func testExecuteWithAttributes() async throws {
        // Arrange
        var trackCount = 0
        appcues.analyticsPublisher.onPublish = { trackingUpdate in
            XCTAssertEqual(trackingUpdate.type, .event(name: "My Custom Event", interactive: true))
            
            [
                "boolean": true,
                "string": "string",
                "int": 10,
                "double": 10.5
            ].verifyPropertiesMatch(trackingUpdate.properties)
            
            trackCount += 1
        }
        let action = AppcuesTrackAction(fromDecoderWith: appcues,
                                        eventName: "My Custom Event",
                                        attributes: [
                                            "boolean": true,
                                            "string": "string",
                                            "int": 10,
                                            "double": 10.5
                                        ])

        // Act
        try await action?.execute()

        // Assert
        XCTAssertEqual(trackCount, 1)
    }

    func testExecuteThrowsWithoutAppcuesInstance() async throws {
        // Arrange
        let action = try XCTUnwrap(AppcuesTrackAction(appcues: nil, eventName: "My Custom Event"))

        // Act/Assert
        await XCTAssertThrowsAsyncError(try await action.execute()) {
            XCTAssertEqual(($0 as? AppcuesTraitError)?.description, "No appcues instance")
        }
    }
}

extension AppcuesTrackAction {
    convenience init?(appcues: Appcues?) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(nil, appcues: appcues))
    }
    convenience init?(fromDecoderWith appcues: Appcues?, eventName: String, attributes: [String: Any]? = nil) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(AppcuesTrackAction.Config(eventName: eventName, attributes: attributes), appcues: appcues))
    }
}
