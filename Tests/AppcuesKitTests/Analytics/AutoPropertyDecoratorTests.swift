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
        let update = TrackingUpdate(type: .screen("screen name"), properties: ["CUSTOM": "value"])

        // Act
        let decorated = decorator.decorate(update)

        // Assert
        XCTAssertEqual(
            [],
            Set(try XCTUnwrap(decorated.context).keys)
                .symmetricDifference(["app_id", "app_version", "screen_title"])
        )
        XCTAssertEqual(
            [],
            Set(try XCTUnwrap(decorated.properties).keys)
                .symmetricDifference(["_identity", "CUSTOM"])
        )
        XCTAssertEqual(
            [],
            Set(try XCTUnwrap(decorated.eventAutoProperties).keys)
                .symmetricDifference(["userId",  "_deviceModel", "_bundlePackageId", "_lastBrowserLanguage", "_localId", "_userAgent", "_appName", "_updatedAt", "_sdkVersion", "_osVersion", "_operatingSystem", "_deviceType", "_appVersion", "_isAnonymous", "_appBuild", "_sdkName", "_appId", "_sessionPageviews", "_currentScreenTitle", "_sessionId"])
        )
    }

    func testEvent() throws {
        // Arrange
        let update = TrackingUpdate(type: .event(name: "appcues:session_started", interactive: true), properties: ["CUSTOM": "value"])

        // Act
        let decorated = decorator.decorate(update)

        // Assert
        XCTAssertEqual(
            [],
            Set(try XCTUnwrap(decorated.context).keys)
                .symmetricDifference(["app_id", "app_version"])
        )
        XCTAssertEqual(
            [],
            Set(try XCTUnwrap(decorated.properties).keys)
                .symmetricDifference(["_identity", "CUSTOM"])
        )
        XCTAssertEqual(
            [],
            Set(try XCTUnwrap (decorated.eventAutoProperties).keys)
                .symmetricDifference(["userId",  "_deviceModel", "_bundlePackageId", "_lastBrowserLanguage", "_localId", "_userAgent", "_appName", "_updatedAt", "_sdkVersion", "_osVersion", "_operatingSystem", "_deviceType", "_appVersion", "_isAnonymous", "_appBuild", "_sdkName", "_appId", "_sessionPageviews", "_sessionRandomizer", "_sessionId"])
        )
    }

    func testProfile() throws {
        // Arrange
        let update = TrackingUpdate(type: .profile, properties: ["CUSTOM": "value"])

        // Act
        let decorated = decorator.decorate(update)

        // Assert
        XCTAssertEqual(
            [],
            Set(try XCTUnwrap(decorated.context).keys)
                .symmetricDifference(["app_id", "app_version"])
        )
        XCTAssertEqual(
            [],
            Set(try XCTUnwrap(decorated.properties).keys)
                .symmetricDifference(["CUSTOM", "userId",  "_deviceModel", "_bundlePackageId", "_lastBrowserLanguage", "_localId", "_userAgent", "_appName", "_updatedAt", "_sdkVersion", "_osVersion", "_operatingSystem", "_deviceType", "_appVersion", "_isAnonymous", "_appBuild", "_sdkName", "_appId", "_sessionPageviews", "_sessionId"])
        )
        XCTAssertNil(decorated.eventAutoProperties)
    }

    func testGroup() throws {
        // Arrange
        let update = TrackingUpdate(type: .group("mygroup"), properties: ["CUSTOM": "value"])

        // Act
        let decorated = decorator.decorate(update)

        // Assert
        XCTAssertNil(decorated.context)
        XCTAssertEqual(
            [],
            Set(try XCTUnwrap(decorated.properties).keys)
                .symmetricDifference(["CUSTOM"])
        )
        XCTAssertNil(decorated.eventAutoProperties)
    }

}
