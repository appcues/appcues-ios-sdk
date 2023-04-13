//
//  AppcuesLaunchExperienceActionTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-01-20.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

@available(iOS 13.0, *)
class AppcuesLaunchExperienceActionTests: XCTestCase {

    var appcues: MockAppcues!

    override func setUpWithError() throws {
        appcues = MockAppcues()
        appcues.sessionID = UUID()
    }

    func testInit() throws {
        // Act
        let action = AppcuesLaunchExperienceAction(configuration: AppcuesExperiencePluginConfiguration(AppcuesLaunchExperienceAction.Config(experienceID: "123")))
        let failedAction = AppcuesLaunchExperienceAction()

        // Assert
        XCTAssertEqual(AppcuesLaunchExperienceAction.type, "@appcues/launch-experience")
        XCTAssertNotNil(action)
        XCTAssertEqual(action?.experienceID, "123")
        XCTAssertNil(failedAction)
    }

    func testExecute() throws {
        // Arrange
        var completionCount = 0
        var loadCount = 0
        appcues.experienceLoader.onLoad = { contentID, published, trigger, completion in
            XCTAssertEqual(contentID, "123")
            guard case .launchExperienceAction = trigger else { return XCTFail() }
            loadCount += 1
            completion?(.success(()))
        }
        let action = AppcuesLaunchExperienceAction(experienceID: "123")

        // Act
        action?.execute(inContext: appcues, completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(loadCount, 1)
    }

    func testExecuteWhenLoadFails() throws {
        // Arrange
        var completionCount = 0
        var loadCount = 0
        appcues.experienceLoader.onLoad = { contentID, published, trigger, completion in
            XCTAssertEqual(contentID, "123")
            guard case .launchExperienceAction = trigger else { return XCTFail() }
            loadCount += 1
            completion?(.failure(AppcuesError.noActiveSession))
        }
        let action = AppcuesLaunchExperienceAction(experienceID: "123")

        // Act
        action?.execute(inContext: appcues, completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(loadCount, 1)
    }

}

@available(iOS 13.0, *)
extension AppcuesLaunchExperienceAction {
    convenience init?() {
        self.init(configuration: AppcuesExperiencePluginConfiguration(nil))
    }
    convenience init?(experienceID: String) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(AppcuesLaunchExperienceAction.Config(experienceID: experienceID)))
    }
}
