//
//  AppcuesContinueActionTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-01-20.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

@available(iOS 13.0, *)
class AppcuesContinueActionTests: XCTestCase {

    var appcues: MockAppcues!

    override func setUpWithError() throws {
        appcues = MockAppcues()
    }

    func testInit() throws {
        // Act
        let indexAction = AppcuesContinueAction(
            configuration: AppcuesExperiencePluginConfiguration(
                AppcuesContinueAction.Config(index: 1, offset: nil, stepID: nil),
                appcues: appcues
            )
        )
        let offsetAction = AppcuesContinueAction(
            configuration: AppcuesExperiencePluginConfiguration(
                AppcuesContinueAction.Config(index: nil, offset: -1, stepID: nil),
                appcues: appcues
            )
        )
        let stepIDAction = AppcuesContinueAction(
            configuration: AppcuesExperiencePluginConfiguration(
                AppcuesContinueAction.Config(index: nil, offset: nil, stepID: UUID(uuidString: "8ebcb374-0eff-45a5-9d62-ffee52d8a57b")),
                appcues: appcues
            )
        )
        let defaultAction = AppcuesContinueAction(
            configuration: AppcuesExperiencePluginConfiguration(
                nil,
                appcues: appcues
            )
        )

        // Assert
        XCTAssertEqual(AppcuesContinueAction.type, "@appcues/continue")
        XCTAssertNotNil(indexAction)
        XCTAssertNotNil(offsetAction)
        XCTAssertNotNil(stepIDAction)
        XCTAssertNotNil(defaultAction)

        guard case .index(1) = indexAction?.stepReference else { return XCTFail() }
        guard case .offset(-1) = offsetAction?.stepReference else { return XCTFail() }
        guard case .stepID(UUID(uuidString: "8ebcb374-0eff-45a5-9d62-ffee52d8a57b")!) = stepIDAction?.stepReference else { return XCTFail() }
        guard case .offset(1) = defaultAction?.stepReference else { return XCTFail() }
    }

    func testExecute() throws {
        // Arrange
        var completionCount = 0
        var showStepCount = 0
        appcues.experienceRenderer.onShowStep = { stepRef, _, completion in
            if case .offset(1) = stepRef {
                showStepCount += 1
            }
            completion?()
        }
        let action = AppcuesContinueAction(appcues: appcues)

        // Act
        action?.execute(completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(showStepCount, 1)
    }

    func testExecuteCompletesWithoutAppcuesInstance() throws {
        // Arrange
        var completionCount = 0
        let action = try XCTUnwrap(AppcuesContinueAction(appcues: nil))

        // Act
        action.execute(completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
    }
}

@available(iOS 13.0, *)
extension AppcuesContinueAction {
    convenience init?(appcues: Appcues?) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(nil, appcues: appcues))
    }
    convenience init?(appcues: Appcues?, index: Int? = nil, offset: Int? = nil, stepID: String? = nil) {
        var uuid: UUID?
        if let stepID = stepID {
            uuid = UUID(uuidString: stepID)
        }
        self.init(configuration: AppcuesExperiencePluginConfiguration(AppcuesContinueAction.Config(index: index, offset: offset, stepID: uuid), appcues: appcues))
    }
}
