//
//  AppcuesRequestReviewActionTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2023-05-02.
//  Copyright © 2023 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class AppcuesRequestReviewActionTests: XCTestCase {

    var appcues: MockAppcues!

    override func setUpWithError() throws {
        appcues = MockAppcues()
    }

    func testInit() throws {
        // Act
        let action = AppcuesRequestReviewAction(configuration: AppcuesExperiencePluginConfiguration(nil, appcues: appcues))

        // Assert
        XCTAssertEqual(AppcuesRequestReviewAction.type, "@appcues/request-review")
        XCTAssertNotNil(action)
    }

    func testExecute() async throws {
        // Arrange
        let action = AppcuesRequestReviewAction(appcues: appcues)

        // Act
        try await action?.execute()
    }

    func testExecuteReturnsWithoutAppcuesInstance() async throws {
        // Arrange
        let action = try XCTUnwrap(AppcuesRequestReviewAction(appcues: nil))

        // Act
        try await action.execute()
    }
}

extension AppcuesRequestReviewAction {
    convenience init?(appcues: Appcues?) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(nil, appcues: appcues))
    }
}
