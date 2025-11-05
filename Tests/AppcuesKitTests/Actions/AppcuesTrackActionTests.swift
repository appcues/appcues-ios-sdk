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

    func testExecute() throws {
        // Arrange
        var completionCount = 0
        var trackCount = 0
        appcues.analyticsPublisher.onPublish = { trackingUpdate in
            XCTAssertEqual(trackingUpdate.type, .event(name: "My Custom Event", interactive: true))
            XCTAssertNil(trackingUpdate.properties)
            trackCount += 1
        }
        let action = AppcuesTrackAction(fromDecoderWith: appcues, eventName: "My Custom Event")

        // Act
        action?.execute(completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(trackCount, 1)
    }
    
    func testExecuteWithAttributes() throws {
        // Arrange
        var completionCount = 0
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
        action?.execute(completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(trackCount, 1)
    }

    func testExecuteCompletesWithoutAppcuesInstance() throws {
        // Arrange
        var completionCount = 0
        let action = try XCTUnwrap(AppcuesTrackAction(appcues: nil, eventName: "My Custom Event"))

        // Act
        action.execute(completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
    }

    func testDecodeFromJSON() throws {
        // Arrange
        let modelData = """
        {
            "on": "tap",
            "type": "@appcues/track",
            "config": {
                "eventName": "Test Event",
                "attributes": {
                    "boolean": false,
                    "string": "test",
                    "int": 100,
                    "double": 2.5,
                    "unsupportedArray": [1, 2],
                    "unsupportedObject": {"key": "value"}
                }
            }
        }
        """.data(using: .utf8)!

        // Act
        let action = try XCTUnwrap(JSONDecoder().decode(Experience.Action.self, from: modelData))
        let instance = try XCTUnwrap(AppcuesTrackAction(
            configuration: AppcuesExperiencePluginConfiguration(action.configDecoder, level: .step, renderContext: .modal, appcues: appcues)
        ))

        // Assert
        XCTAssertEqual(instance.eventName, "Test Event")
        XCTAssertNotNil(instance.attributes)
        // Only supported types should be included
        XCTAssertEqual(instance.attributes?.count, 4)
        XCTAssertEqual(instance.attributes?["boolean"] as? Bool, false)
        XCTAssertEqual(instance.attributes?["string"] as? String, "test")
        XCTAssertEqual(instance.attributes?["int"] as? Int, 100)
        XCTAssertEqual(instance.attributes?["double"] as? Double, 2.5)
        XCTAssertNil(instance.attributes?["unsupportedArray"])
        XCTAssertNil(instance.attributes?["unsupportedObject"])
    }

    func testDecodeFromJSONWithNoAttributes() throws {
        // Arrange
        let modelData = """
        {
            "on": "tap",
            "type": "@appcues/track",
            "config": {
                "eventName": "Test Event"
            }
        }
        """.data(using: .utf8)!

        // Act
        let action = try XCTUnwrap(JSONDecoder().decode(Experience.Action.self, from: modelData))
        let instance = try XCTUnwrap(AppcuesTrackAction(
            configuration: AppcuesExperiencePluginConfiguration(action.configDecoder, level: .step, renderContext: .modal, appcues: appcues)
        ))

        // Assert
        XCTAssertEqual(instance.eventName, "Test Event")
        XCTAssertNil(instance.attributes)
    }
}

@available(iOS 13.0, *)
extension AppcuesTrackAction {
    convenience init?(appcues: Appcues?) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(nil, appcues: appcues))
    }
    convenience init?(fromDecoderWith appcues: Appcues?, eventName: String, attributes: [String: Any]? = nil) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(AppcuesTrackAction.Config(eventName: eventName, attributes: attributes), appcues: appcues))
    }
}
