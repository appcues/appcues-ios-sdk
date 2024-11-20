//
//  AppcuesStepTransitionAnimationTraitTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2023-05-16.
//  Copyright © 2023 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class AppcuesStepTransitionAnimationTraitTests: XCTestCase {

    var appcues: MockAppcues!

    let metadataDelegate = AppcuesTraitMetadataDelegate()
    var metadataUpdates: [AppcuesTraitMetadata] = []

    var containerController: AppcuesExperienceContainerViewController!

    override func setUpWithError() throws {
        appcues = MockAppcues()
        metadataUpdates = []
        metadataDelegate.registerHandler(for: "test", animating: false) { metadata in self.metadataUpdates.append(metadata) }

        containerController = DefaultContainerViewController(stepControllers: [], pageMonitor: AppcuesExperiencePageMonitor(numberOfPages: 0, currentPage: 0))
    }

    @MainActor
    func testInit() throws {
        // Act
        let trait = AppcuesStepTransitionAnimationTrait(appcues: appcues)

        // Assert
        XCTAssertEqual(AppcuesStepTransitionAnimationTrait.type, "@appcues/step-transition-animation")
        XCTAssertNotNil(trait)
    }

    func testValueMapping() throws {
        // Assert
        XCTAssertEqual(
            AppcuesStepTransitionAnimationTrait.Easing.linear.curve,
            UIView.AnimationOptions.curveLinear
        )
        XCTAssertEqual(
            AppcuesStepTransitionAnimationTrait.Easing.easeIn.curve,
            UIView.AnimationOptions.curveEaseIn
        )
        XCTAssertEqual(
            AppcuesStepTransitionAnimationTrait.Easing.easeOut.curve,
            UIView.AnimationOptions.curveEaseOut
        )
        XCTAssertEqual(
            AppcuesStepTransitionAnimationTrait.Easing.easeInOut.curve,
            UIView.AnimationOptions.curveEaseInOut
        )

        XCTAssertEqual(
            AppcuesStepTransitionAnimationTrait.Easing.linear.timingFunction,
            CAMediaTimingFunctionName.linear
        )
        XCTAssertEqual(
            AppcuesStepTransitionAnimationTrait.Easing.easeIn.timingFunction,
            CAMediaTimingFunctionName.easeIn
        )
        XCTAssertEqual(
            AppcuesStepTransitionAnimationTrait.Easing.easeOut.timingFunction,
            CAMediaTimingFunctionName.easeOut
        )
        XCTAssertEqual(
            AppcuesStepTransitionAnimationTrait.Easing.easeInOut.timingFunction,
            CAMediaTimingFunctionName.easeInEaseOut
        )

        XCTAssertNil(AppcuesStepTransitionAnimationTrait.Easing(metadataValue: nil))
        XCTAssertEqual(AppcuesStepTransitionAnimationTrait.Easing(metadataValue: "linear"), .linear)
        XCTAssertEqual(AppcuesStepTransitionAnimationTrait.Easing(metadataValue: "easeIn"), .easeIn)
        XCTAssertEqual(AppcuesStepTransitionAnimationTrait.Easing(metadataValue: "easeOut"), .easeOut)
        XCTAssertEqual(AppcuesStepTransitionAnimationTrait.Easing(metadataValue: "easeInOut"), .easeInOut)
    }

    @MainActor
    func testDecorate() throws {
        // Arrange
        let trait = try XCTUnwrap(AppcuesStepTransitionAnimationTrait(appcues: appcues))
        trait.metadataDelegate = metadataDelegate

        // Act
        try trait.decorate(containerController: containerController)
        metadataDelegate.publish()

        // Assert
        XCTAssertEqual(metadataUpdates.count, 1)
        let latestMetadata = try XCTUnwrap(metadataUpdates.last)

        XCTAssertEqual(latestMetadata["animationDuration"], 0.3)
        XCTAssertEqual(latestMetadata["animationEasing"], "linear")
    }

    @MainActor
    func testUndecorate() throws {
        // Arrange
        let trait = try XCTUnwrap(AppcuesStepTransitionAnimationTrait(appcues: appcues))
        trait.metadataDelegate = metadataDelegate

        try trait.decorate(containerController: containerController)
        metadataDelegate.publish()

        // Act
        try trait.undecorate(containerController: containerController)
        metadataDelegate.publish()

        // Assert
        XCTAssertEqual(metadataUpdates.count, 2)
        let latestMetadata = try XCTUnwrap(metadataUpdates.last)

        let animationDuration: TimeInterval? = latestMetadata["animationDuration"]
        XCTAssertNil(animationDuration)
        let easing: String? = latestMetadata["animationEasing"]
        XCTAssertNil(easing)
    }

}

extension AppcuesStepTransitionAnimationTrait {
    convenience init?(appcues: Appcues?) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(nil, appcues: appcues))
    }

    convenience init?(appcues: Appcues?, duration: Int, easing: Easing) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(AppcuesStepTransitionAnimationTrait.Config(duration: duration, easing: easing), appcues: appcues))
    }
}
