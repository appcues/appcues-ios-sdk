//
//  AutoPropertyDecoratorTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-04-26.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class AutoPropertyDecoratorTests: XCTestCase {

    var appcues: MockAppcues!
    var decorator: AutoPropertyDecorator!

    override func setUp() {
        let config = Appcues.Config(accountID: "00000", applicationID: "abc")
        appcues = MockAppcues(config: config)
        appcues.sessionID = UUID()
        decorator = AutoPropertyDecorator(container: appcues.container)
    }

    // These tests assert that the correct property keys exist, but ignores the values
    // because the values are too dynamic to be be helpfully testable.
    // For example, `_appVersion` is the Xcode version, which would make tests flaky.

    func testScreen() throws {
        // Arrange
        let update = TrackingUpdate(type: .screen("screen name"), properties: ["CUSTOM": "value"], isInternal: false)

        // Act
        let decorated = decorator.decorate(update)

        // Assert
        let expectedContextKeys = ["app_id", "app_version", "screen_title"]
        XCTAssertEqual([], Set(try XCTUnwrap(decorated.context).keys).symmetricDifference(expectedContextKeys))
        let expectedPropertyKeys = ["_identity", "CUSTOM"]
        XCTAssertEqual([], Set(try XCTUnwrap(decorated.properties).keys).symmetricDifference(expectedPropertyKeys))
        let expectedEventAutoPropertyKeys = ["userId",  "_deviceModel", "_bundlePackageId", "_lastBrowserLanguage", "_localId", "_appName", "_updatedAt", "_sdkVersion", "_osVersion", "_operatingSystem", "_deviceType", "_appVersion", "_isAnonymous", "_appBuild", "_sdkName", "_appId", "_sessionPageviews", "_currentScreenTitle", "_sessionId"]
        XCTAssertEqual([], Set(try XCTUnwrap(decorated.eventAutoProperties).keys).symmetricDifference(expectedEventAutoPropertyKeys))
    }

    func testEvent() throws {
        // Arrange
        let update = TrackingUpdate(type: .event(name: "appcues:session_started", interactive: true), properties: ["CUSTOM": "value"], isInternal: false)

        // Act
        let decorated = decorator.decorate(update)

        // Assert
        let expectedContextKeys = ["app_id", "app_version"]
        XCTAssertEqual([], Set(try XCTUnwrap(decorated.context).keys).symmetricDifference(expectedContextKeys))
        let expectedPropertyKeys = ["_identity", "CUSTOM"]
        XCTAssertEqual([], Set(try XCTUnwrap(decorated.properties).keys).symmetricDifference(expectedPropertyKeys))
        let expectedEventAutoPropertyKeys = ["userId",  "_deviceModel", "_bundlePackageId", "_lastBrowserLanguage", "_localId", "_appName", "_updatedAt", "_sdkVersion", "_osVersion", "_operatingSystem", "_deviceType", "_appVersion", "_isAnonymous", "_appBuild", "_sdkName", "_appId", "_sessionPageviews", "_sessionRandomizer", "_sessionId"]
        XCTAssertEqual([], Set(try XCTUnwrap(decorated.eventAutoProperties).keys).symmetricDifference(expectedEventAutoPropertyKeys))
    }

    func testProfile() throws {
        // Arrange
        let update = TrackingUpdate(type: .profile(interactive: true), properties: ["CUSTOM": "value"], isInternal: false)

        // Act
        let decorated = decorator.decorate(update)

        // Assert
        let expectedContextKeys = ["app_id", "app_version"]
        XCTAssertEqual([], Set(try XCTUnwrap(decorated.context).keys).symmetricDifference(expectedContextKeys))
        let expectedPropertyKeys = ["CUSTOM", "userId",  "_deviceModel", "_bundlePackageId", "_lastBrowserLanguage", "_localId", "_appName", "_updatedAt", "_sdkVersion", "_osVersion", "_operatingSystem", "_deviceType", "_appVersion", "_isAnonymous", "_appBuild", "_sdkName", "_appId", "_sessionPageviews", "_sessionId"]
        XCTAssertEqual([], Set(try XCTUnwrap(decorated.properties).keys).symmetricDifference(expectedPropertyKeys))
        XCTAssertNil(decorated.eventAutoProperties)
    }

    func testGroup() throws {
        // Arrange
        let update = TrackingUpdate(type: .group("mygroup"), properties: ["CUSTOM": "value"], isInternal: false)

        // Act
        let decorated = decorator.decorate(update)

        // Assert
        XCTAssertNil(decorated.context)
        let expectedPropertyKeys = ["CUSTOM"]
        XCTAssertEqual([], Set(try XCTUnwrap(decorated.properties).keys).symmetricDifference(expectedPropertyKeys))
        XCTAssertNil(decorated.eventAutoProperties)
    }

    func testAdditionalAutoProperty() throws {
        // Arrange
        // need to make a custom config and decorator based off of it for this test
        let config = Appcues.Config(accountID: "00000", applicationID: "abc")
            .additionalAutoProperties(["_myProp": 101, "_sdkName": "test-name"])
        appcues = MockAppcues(config: config)
        appcues.sessionID = UUID()
        decorator = AutoPropertyDecorator(container: appcues.container)
        let update = TrackingUpdate(type: .screen("screen name"), isInternal: false)

        // Act
        let decorated = decorator.decorate(update)

        // Assert
        let expectedEventAutoPropertyKeys = ["userId",  "_deviceModel", "_bundlePackageId", "_lastBrowserLanguage", "_localId", "_appName", "_updatedAt", "_sdkVersion", "_osVersion", "_operatingSystem", "_deviceType", "_appVersion", "_isAnonymous", "_appBuild", "_sdkName", "_appId", "_sessionPageviews", "_currentScreenTitle", "_sessionId", "_myProp"]
        XCTAssertEqual([], Set(try XCTUnwrap(decorated.eventAutoProperties).keys).symmetricDifference(expectedEventAutoPropertyKeys))

        // new custom prop
        XCTAssertEqual(101, (try XCTUnwrap(decorated.eventAutoProperties?["_myProp"])) as? Int)
        // cannot overwrite this core prop
        XCTAssertNotEqual("test-name", (try XCTUnwrap(decorated.eventAutoProperties?["_sdkName"])) as? String)
    }

    func testProfilePropertiesOnSubsequentEvent() throws {
        // Arrange
        let profileUpdate = TrackingUpdate(type: .profile(interactive: true), properties: ["PROFILE_PROPERTY": "value"], isInternal: false)
        _ = decorator.decorate(profileUpdate)

        let update = TrackingUpdate(type: .event(name: "appcues:v2:step_seen", interactive: true), isInternal: false)

        // Act
        let decorated = decorator.decorate(update)

        // Assert
        let expectedContextKeys = ["app_id", "app_version"]
        XCTAssertEqual([], Set(try XCTUnwrap(decorated.context).keys).symmetricDifference(expectedContextKeys))
        let expectedPropertyKeys = ["_identity"]
        XCTAssertEqual([], Set(try XCTUnwrap(decorated.properties).keys).symmetricDifference(expectedPropertyKeys))
        let expectedEventAutoPropertyKeys = ["userId",  "_deviceModel", "_bundlePackageId", "_lastBrowserLanguage", "_localId", "_appName", "_updatedAt", "_sdkVersion", "_osVersion", "_operatingSystem", "_deviceType", "_appVersion", "_isAnonymous", "_appBuild", "_sdkName", "_appId", "_sessionPageviews", "_sessionId", "PROFILE_PROPERTY"]
        XCTAssertEqual([], Set(try XCTUnwrap(decorated.eventAutoProperties).keys).symmetricDifference(expectedEventAutoPropertyKeys))
    }
}
