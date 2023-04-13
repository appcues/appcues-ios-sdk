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
        let action = AppcuesUpdateProfileAction(properties: ["profile_attribute": "value"])
        let failedAction = AppcuesUpdateProfileAction(configuration: AppcuesExperiencePluginConfiguration(nil))

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
            XCTAssertEqual(properties?.count, 3)
            XCTAssertEqual(properties?["profile_attribute"] as? String, "value")
            XCTAssertEqual(properties?["int_value"] as? Int, 5)
            XCTAssertEqual(properties?["bool_value"] as? Bool, false)

            identifyCount += 1
        }
        let action = AppcuesUpdateProfileAction(properties: [
            "profile_attribute": "value",
            "int_value": 5,
            "bool_value": false
        ])

        // Act
        action?.execute(inContext: appcues, completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(identifyCount, 1)
    }
}

@available(iOS 13.0, *)
extension AppcuesUpdateProfileAction {
    convenience init?() {
        self.init(configuration: AppcuesExperiencePluginConfiguration(nil))
    }
    convenience init?(properties: [String: Any]) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(AppcuesUpdateProfileAction.Config(properties: properties)))
    }
}
