//
//  AppcuesDelayActionTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2024-06-05.
//  Copyright © 2024 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class AppcuesDelayActionTests: XCTestCase {

    func testInit() throws {
        // Act
        let action = AppcuesDelayAction(appcues: nil, duration: 500)
        let failedAction = AppcuesUpdateProfileAction(configuration: AppcuesExperiencePluginConfiguration(nil, appcues: nil))

        // Assert
        XCTAssertEqual(AppcuesDelayAction.type, "@appcues/delay")
        XCTAssertNotNil(action)
        XCTAssertNil(failedAction)
    }

    func testExecute() async throws {
        // Arrange
        let action = AppcuesDelayAction(duration: 0.5)

        // Act
        try await action.execute()
    }
}

extension AppcuesDelayAction {
    convenience init?(appcues: Appcues?) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(nil, appcues: appcues))
    }
    convenience init?(appcues: Appcues?, duration: Int) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(AppcuesDelayAction.Config(duration: duration), appcues: appcues))
    }
}
