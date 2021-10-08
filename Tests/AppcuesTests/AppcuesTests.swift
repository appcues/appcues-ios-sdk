//
//  AppcuesTests.swift
//  AppcuesTests
//
//  Created by Matt on 2021-10-06.
//  Copyright © 2021 Appcues. All rights reserved.
//

import XCTest
@testable import Appcues

class AppcuesTests: XCTestCase {

    var instance: Appcues!

    override func setUpWithError() throws {
        instance = Appcues(config: Config(accountID: "17361").apiHost("api-main.staging.us-west-2.aws.appcues.net"))
    }

    override func tearDownWithError() throws {
    }

    func testIdentify() throws {
        instance.identify(userID: "abc", properties: [:])
        XCTAssertEqual(instance.log.count, 1)
        XCTAssertEqual(instance.log.first, "Appcues.identify(userId: abc)")
    }

    func testTrackEvent() throws {
        instance.track(event: "eventName", properties: [:])
        XCTAssertEqual(instance.log.count, 1)
        XCTAssertEqual(instance.log.first, "Appcues.track(event: eventName)")
    }

    func testTrackScreen() throws {
        instance.screen(title: "Homescreen", properties: [:])
        XCTAssertEqual(instance.log.count, 1)
        XCTAssertEqual(instance.log.first, "Appcues.screen(title: Homescreen)")
    }
}
