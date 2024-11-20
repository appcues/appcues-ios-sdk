//
//  AppcuesLaunchExperienceActionTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-01-20.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class AppcuesLaunchExperienceActionTests: XCTestCase {

    var appcues: MockAppcues!

    override func setUpWithError() throws {
        appcues = MockAppcues()
        appcues.sessionID = UUID()
    }

    func testInit() throws {
        // Act
        let action = AppcuesLaunchExperienceAction(configuration: AppcuesExperiencePluginConfiguration(AppcuesLaunchExperienceAction.Config(experienceID: "123"), appcues: appcues))
        let failedAction = AppcuesLaunchExperienceAction(appcues: appcues)

        // Assert
        XCTAssertEqual(AppcuesLaunchExperienceAction.type, "@appcues/launch-experience")
        XCTAssertNotNil(action)
        XCTAssertEqual(action?.experienceID, "123")
        XCTAssertNil(failedAction)
    }

    func testExecute() async throws {
        // Arrange
        var loadCount = 0
        appcues.contentLoader.onLoad = { contentID, published, trigger in
            XCTAssertEqual(contentID, "123")
            guard case .launchExperienceAction = trigger else { return XCTFail() }
            loadCount += 1
        }
        let action = AppcuesLaunchExperienceAction(appcues: appcues, experienceID: "123")

        // Act
        try await action?.execute()

        // Assert
        XCTAssertEqual(loadCount, 1)
    }

    func testExecuteWhenLoadFails() async throws {
        // Arrange
        var loadCount = 0
        appcues.contentLoader.onLoad = { contentID, published, trigger in
            XCTAssertEqual(contentID, "123")
            guard case .launchExperienceAction = trigger else { return XCTFail() }
            loadCount += 1
            throw AppcuesError.noActiveSession
        }
        let action = AppcuesLaunchExperienceAction(appcues: appcues, experienceID: "123")

        // Act/Assert
        await XCTAssertThrowsAsyncError(try await action?.execute()) {
            XCTAssertEqual($0 as? AppcuesError, AppcuesError.noActiveSession)
        }
        XCTAssertEqual(loadCount, 1)
    }

    func testExecuteThrowsWithoutAppcuesInstance() async throws {
        // Arrange
        let action = try XCTUnwrap(AppcuesLaunchExperienceAction(appcues: nil, experienceID: "123"))

        // Act/Assert
        await XCTAssertThrowsAsyncError(try await action.execute()) {
            XCTAssertEqual(($0 as? AppcuesTraitError)?.description, "No appcues instance")
        }
    }
}

extension AppcuesLaunchExperienceAction {
    convenience init?(appcues: Appcues?) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(nil, appcues: appcues))
    }
    convenience init?(appcues: Appcues?, experienceID: String) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(AppcuesLaunchExperienceAction.Config(experienceID: experienceID), appcues: appcues))
    }
}
