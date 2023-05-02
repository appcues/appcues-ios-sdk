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
        let action = AppcuesUpdateProfileAction(appcues: appcues, properties: ["profile_attribute": "value"])
        let failedAction = AppcuesUpdateProfileAction(configuration: AppcuesExperiencePluginConfiguration(nil, appcues: appcues))

        // Assert
        XCTAssertEqual(AppcuesUpdateProfileAction.type, "@appcues/update-profile")
        XCTAssertNotNil(action)
        XCTAssertEqual(action?.properties["profile_attribute"] as? String, "value")
        XCTAssertNil(failedAction)
    }

    func testInitFromJSON() throws {
        let modelData = """
        {
            "on": "tap",
            "type": "@appcues/update-profile",
            "config": {
                "attribute1": "Hello!",
                "attribute2": 0,
                "attribute3": false,
                "attribute4": 3.14
            }
        }
        """.data(using: .utf8)!

        let action = try XCTUnwrap(JSONDecoder().decode(Experience.Action.self, from: modelData))
        let instance = try XCTUnwrap(AppcuesUpdateProfileAction(
            configuration: AppcuesExperiencePluginConfiguration(action.configDecoder, level: .step, appcues: appcues)
        ))

        XCTAssertEqual(instance.properties.count, 4)
        XCTAssertEqual(instance.properties["attribute1"] as? String, "Hello!")
        XCTAssertEqual(instance.properties["attribute2"] as? Int, 0)
        XCTAssertEqual(instance.properties["attribute3"] as? Bool, false)
        XCTAssertEqual(instance.properties["attribute4"] as? Double, 3.14)

    }

    func testExecute() throws {
        // Arrange
        var completionCount = 0
        var identifyCount = 0
        appcues.onIdentify = { userID, properties in
            XCTAssertEqual(userID, "user-id")
            XCTAssertEqual(properties?.count, 3)
            XCTAssertEqual(properties?["profile_attribute"] as? String, "value")
            XCTAssertEqual(properties?["int_value"] as? Int, 5)
            XCTAssertEqual(properties?["bool_value"] as? Bool, false)

            identifyCount += 1
        }
        let action = AppcuesUpdateProfileAction(
            appcues: appcues,
            properties: [
                "profile_attribute": "value",
                "int_value": 5,
                "bool_value": false
            ]
        )

        // Act
        action?.execute(completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(identifyCount, 1)
    }

    func testExecuteCompletesWithoutAppcuesInstance() throws {
        // Arrange
        var completionCount = 0
        let action = try XCTUnwrap(AppcuesUpdateProfileAction(appcues: nil, properties: ["profile_attribute": "value"]))

        // Act
        action.execute(completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
    }
}

@available(iOS 13.0, *)
extension AppcuesUpdateProfileAction {
    convenience init?(appcues: Appcues?) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(nil, appcues: appcues))
    }
    convenience init?(appcues: Appcues?, properties: [String: Any]) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(AppcuesUpdateProfileAction.Config(properties: properties), appcues: appcues))
    }
}
