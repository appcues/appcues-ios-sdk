//
//  AppcuesTargetRectangleTraitTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2023-05-16.
//  Copyright © 2023 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class AppcuesTargetRectangleTraitTests: XCTestCase {

    var appcues: MockAppcues!

    let metadataDelegate = AppcuesTraitMetadataDelegate()
    var metadataUpdates: [AppcuesTraitMetadata] = []

    var backdropView: UIView!

    override func setUpWithError() throws {
        appcues = MockAppcues()
        metadataUpdates = []
        metadataDelegate.registerHandler(for: "test", animating: false) { metadata in self.metadataUpdates.append(metadata) }

        backdropView = UIView(frame: CGRect(x: 0, y: 0, width: 500, height: 1000))
        let window = UIWindow(frame: .zero)
        window.addSubview(backdropView)
    }

    func testInit() throws {
        // Act
        let nilConfigTrait = AppcuesTargetRectangleTrait(configuration: AppcuesExperiencePluginConfiguration(nil))
        let trait = AppcuesTargetRectangleTrait(appcues: appcues)

        // Assert
        XCTAssertEqual(AppcuesTargetRectangleTrait.type, "@appcues/target-rectangle")
        XCTAssertNil(nilConfigTrait)
        XCTAssertNotNil(trait)
    }

    func testDecorate() throws {
        // Arrange
        let trait = try XCTUnwrap(AppcuesTargetRectangleTrait(appcues: appcues))
        trait.metadataDelegate = metadataDelegate

        // Act
        try trait.decorate(backdropView: backdropView)
        metadataDelegate.publish()

        // Assert
        XCTAssertEqual(metadataUpdates.count, 1)
        let latestMetadata = try XCTUnwrap(metadataUpdates.last)

        XCTAssertEqual(latestMetadata["targetRectangle"], CGRect(x: 0, y: 0, width: 0, height: 0))
    }

    func testFrameCalculation() throws {
        // Arrange
        let trait = try XCTUnwrap(AppcuesTargetRectangleTrait(appcues: appcues, x: -10, y: 20, width: 100, height: 60, relativeX: 0.5, relativeY: 0.5))
        trait.metadataDelegate = metadataDelegate

        // Act
        try trait.decorate(backdropView: backdropView)
        metadataDelegate.publish()

        // Assert
        XCTAssertEqual(metadataUpdates.count, 1)
        let latestMetadata = try XCTUnwrap(metadataUpdates.last)

        XCTAssertEqual(latestMetadata["targetRectangle"], CGRect(x: 240, y: 520, width: 100, height: 60))
    }

    func testFrameRecalculation() throws {
        // Arrange
        let trait = try XCTUnwrap(AppcuesTargetRectangleTrait(appcues: appcues, x: -10, y: 20, width: 100, height: 60, relativeX: 0.5, relativeY: 0.5))
        trait.metadataDelegate = metadataDelegate

        try trait.decorate(backdropView: backdropView)
        metadataDelegate.publish()

        // Act
        backdropView.frame = CGRect(x: 0, y: 0, width: 1000, height: 500)
        backdropView.setNeedsLayout()
        backdropView.layoutIfNeeded()

        // Assert
        XCTAssertEqual(metadataUpdates.count, 2)
        let latestMetadata = try XCTUnwrap(metadataUpdates.last)

        XCTAssertEqual(latestMetadata["targetRectangle"], CGRect(x: 490, y: 270, width: 100, height: 60))
    }

    func testUndecorate() throws {
        // Arrange
        let trait = try XCTUnwrap(AppcuesTargetRectangleTrait(appcues: appcues))
        trait.metadataDelegate = metadataDelegate

        try trait.decorate(backdropView: backdropView)
        metadataDelegate.publish()

        // Act
        try trait.undecorate(backdropView: backdropView)
        metadataDelegate.publish()

        // Assert
        XCTAssertEqual(metadataUpdates.count, 2)
        let latestMetadata = try XCTUnwrap(metadataUpdates.last)

        let targetRectangle: CGRect? = latestMetadata["targetRectangle"]
        XCTAssertNil(targetRectangle)
        let contentPreferredPosition: ContentPosition? = latestMetadata["contentPreferredPosition"]
        XCTAssertNil(contentPreferredPosition)
        let contentDistanceFromTarget: CGFloat? = latestMetadata["contentDistanceFromTarget"]
        XCTAssertNil(contentDistanceFromTarget)
    }

}

extension AppcuesTargetRectangleTrait {
    convenience init?(
        appcues: Appcues?,
        contentPreferredPosition: ContentPosition? = nil,
        contentDistanceFromTarget: Double? = nil,
        x: Double? = nil,
        y: Double? = nil,
        width: Double? = nil,
        height: Double? = nil,
        relativeX: Double? = nil,
        relativeY: Double? = nil,
        relativeWidth: Double? = nil,
        relativeHeight: Double? = nil
    ) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(AppcuesTargetRectangleTrait.Config(
            contentPreferredPosition: contentPreferredPosition,
            contentDistanceFromTarget: contentDistanceFromTarget,
            x: x,
            y: y,
            width: width,
            height: height,
            relativeX: relativeX,
            relativeY: relativeY,
            relativeWidth: relativeWidth,
            relativeHeight: relativeHeight
        ), appcues: appcues))
    }
}
