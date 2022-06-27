//
//  AnalyticsBroadcasterTests.swift
//  AppcuesKit
//
//  Created by James Ellis on 6/27/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class AnalyticsBroadcasterTests: XCTestCase {

    var broadcaster: AnalyticsBroadcaster!
    var appcues: MockAppcues!
    var delegate: MockAnalyticsDelegate!

    override func setUpWithError() throws {
        let config = Appcues.Config(accountID: "00000", applicationID: "abc")

        appcues = MockAppcues(config: config)
        delegate = MockAnalyticsDelegate()
        broadcaster = AnalyticsBroadcaster(container: appcues.container)
        appcues.analyticsDelegate = delegate
    }

    func testBroadcastEvent() throws {
        // Act
        broadcaster.track(update: TrackingUpdate(type: .event(name: "my event", interactive: true), properties: ["key": "value"], context: nil, isInternal: true))

        // Assert
        XCTAssertEqual(delegate.lastAnalytic, .event)
        XCTAssertEqual(delegate.lastValue, "my event")
        ["key": "value"].verifyPropertiesMatch(delegate.lastProperties)
        XCTAssertEqual(delegate.lastIsInternal, true)
    }

    func testBroadcastScreen() throws {
        // Act
        broadcaster.track(update: TrackingUpdate(type: .screen("screen name"), properties: ["key": "value"], context: nil, isInternal: false))

        // Assert
        XCTAssertEqual(delegate.lastAnalytic, .screen)
        XCTAssertEqual(delegate.lastValue, "screen name")
        ["key": "value"].verifyPropertiesMatch(delegate.lastProperties)
        XCTAssertEqual(delegate.lastIsInternal, false)
    }

    func testBroadcastGroup() throws {
        // Act
        broadcaster.track(update: TrackingUpdate(type: .group("group name"), properties: ["key": "value"], context: nil, isInternal: false))

        // Assert
        XCTAssertEqual(delegate.lastAnalytic, .group)
        XCTAssertEqual(delegate.lastValue, "group name")
        ["key": "value"].verifyPropertiesMatch(delegate.lastProperties)
        XCTAssertEqual(delegate.lastIsInternal, false)
    }

    func testBroadcastProfile() throws {
        // Act
        broadcaster.track(update: TrackingUpdate(type: .profile, properties: ["key": "value"], context: nil, isInternal: false))

        // Assert
        XCTAssertEqual(delegate.lastAnalytic, .identify)
        XCTAssertEqual(delegate.lastValue, "user-id")
        ["key": "value"].verifyPropertiesMatch(delegate.lastProperties)
        XCTAssertEqual(delegate.lastIsInternal, false)
    }
}

class MockAnalyticsDelegate: AppcuesAnalyticsDelegate {
    var lastAnalytic: AppcuesAnalytic?
    var lastValue: String?
    var lastProperties: [String: Any]?
    var lastIsInternal: Bool?

    func didTrack(analytic: AppcuesAnalytic, value: String?, properties: [String: Any]?, isInternal: Bool) {
        lastAnalytic = analytic
        lastValue = value
        lastProperties = properties
        lastIsInternal = isInternal
    }
}
