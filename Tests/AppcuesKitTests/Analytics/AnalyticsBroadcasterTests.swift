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
    var delegate: AnalyticsDelegate!

    override func setUpWithError() throws {
        let config = Appcues.Config(accountID: "00000", applicationID: "abc")

        appcues = MockAppcues(config: config)
        broadcaster = AnalyticsBroadcaster(container: appcues.container)
        appcues.analyticsDelegate = delegate
    }

    func testAnalyticsBroadcast() throws {

    }
}

class AnalyticsDelegate: AppcuesAnalyticsDelegate {
    func didTrack(analytic: AppcuesAnalytic, value: String?, properties: [String : Any]?, isInternal: Bool) {

    }
}
