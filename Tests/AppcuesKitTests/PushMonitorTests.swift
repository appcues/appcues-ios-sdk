//
//  PushMonitorTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2024-02-26.
//  Copyright © 2024 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class PushMonitorTests: XCTestCase {

    var pushMonitor: PushMonitor!
    var appcues: MockAppcues!

    override func setUp() {
        let config = Appcues.Config(accountID: "00000", applicationID: "abc")
        appcues = MockAppcues(config: config)
        pushMonitor = PushMonitor(container: appcues.container)
    }

    func testNoTokenNotAuthorized() throws {
        // Arrange
        appcues.storage.pushToken = nil
        pushMonitor.mockPushStatus(.denied)

        // Assert
        XCTAssertFalse(pushMonitor.pushEnabled)
        XCTAssertFalse(pushMonitor.pushBackgroundEnabled)
    }

    func testNoTokenAuthorized() throws {
        // Arrange
        appcues.storage.pushToken = nil
        pushMonitor.mockPushStatus(.authorized)

        // Assert
        XCTAssertFalse(pushMonitor.pushEnabled)
        XCTAssertFalse(pushMonitor.pushBackgroundEnabled)
    }

    func testTokenNotAuthorized() throws {
        // Arrange
        appcues.storage.pushToken = "<some-token>"
        pushMonitor.mockPushStatus(.denied)

        // Assert
        XCTAssertFalse(pushMonitor.pushEnabled)
        XCTAssertTrue(pushMonitor.pushBackgroundEnabled)
    }

    func testTokenAuthorized() throws {
        // Arrange
        appcues.storage.pushToken = "<some-token>"
        pushMonitor.mockPushStatus(.authorized)

        // Assert
        XCTAssertTrue(pushMonitor.pushEnabled)
        XCTAssertTrue(pushMonitor.pushBackgroundEnabled)
    }

}
