//
//  AppcuesTargetElementTraitTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2023-05-16.
//  Copyright © 2023 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

@available(iOS 13.0, *)
class AppcuesTargetElementTraitTests: XCTestCase {

    var appcues: MockAppcues!

    let metadataDelegate = AppcuesTraitMetadataDelegate()
    var metadataUpdates: [AppcuesTraitMetadata] = []

    var window: UIWindow!
    var rootViewController: UIViewController!
    var backdropView: UIView!

    override func setUpWithError() throws {
        appcues = MockAppcues()
        metadataUpdates = []
        metadataDelegate.registerHandler(for: "test", animating: false) { metadata in self.metadataUpdates.append(metadata) }

        backdropView = UIView(frame: CGRect(x: 0, y: 0, width: 500, height: 1000))

        rootViewController = UIViewController()
        _ = rootViewController.view
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 500, height: 1000))
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()
        window.addSubview(backdropView)
    }

    override func tearDownWithError() throws {
        try XCTUnwrap(Appcues.elementTargeting as? UIKitElementTargeting).window = nil
    }

    func testInit() throws {
        // Act
        let nilConfigTrait = AppcuesTargetElementTrait(configuration: AppcuesExperiencePluginConfiguration(nil))
        let trait = AppcuesTargetElementTrait(appcues: appcues, selector: [:])

        // Assert
        XCTAssertEqual(AppcuesTargetElementTrait.type, "@appcues/target-element")
        XCTAssertNil(nilConfigTrait)
        XCTAssertNotNil(trait)
    }

    func testDecorateThrowsInvalidSelector() throws {
        // Arrange
        let trait = try XCTUnwrap(AppcuesTargetElementTrait(appcues: appcues, selector: [:]))

        // Act/Assert
        XCTAssertThrowsError(try trait.decorate(backdropView: backdropView)) {
            XCTAssertEqual(($0 as? AppcuesTraitError)?.description, "Invalid selector [:]")
        }
    }

    func testDecorateThrowsNoLayout() throws {
        // Arrange
        let trait = try XCTUnwrap(AppcuesTargetElementTrait(appcues: appcues, selector: ["accessibilityIdentifier":"myID"]))

        // Act/Assert
        XCTAssertThrowsError(try trait.decorate(backdropView: backdropView)) {
            XCTAssertEqual(($0 as? AppcuesTraitError)?.description, "Could not read application layout information")
        }
    }

    func testDecorateThrowsNoMatch() throws {
        // Arrange
        try XCTUnwrap(Appcues.elementTargeting as? UIKitElementTargeting).window = window

        // A hidden view should be ignored
        let view1 = UIView(frame: CGRect(x: 20, y: 20, width: 100, height: 100), accessibilityIdentifier: "myID")
        view1.isHidden = true
        rootViewController.view.addSubview(view1)

        // A view outside the window from should be ignored
        let view2 = UIView(frame: CGRect(x: 1040, y: 20, width: 100, height: 100), accessibilityIdentifier: "myID")
        rootViewController.view.addSubview(view2)

        let trait = try XCTUnwrap(AppcuesTargetElementTrait(appcues: appcues, selector: ["accessibilityIdentifier":"myID"]))

        // Act/Assert
        XCTAssertThrowsError(try trait.decorate(backdropView: backdropView)) {
            XCTAssertEqual(($0 as? AppcuesTraitError)?.description, #"No view matching selector ["accessibilityIdentifier": "myID"]"#)
        }
    }

    func testDecorateThrowsMultipleMatch() throws {
        // Arrange
        try XCTUnwrap(Appcues.elementTargeting as? UIKitElementTargeting).window = window

        let view1 = UIView(frame: CGRect(x: 20, y: 20, width: 100, height: 100), accessibilityIdentifier: "myID")
        rootViewController.view.addSubview(view1)
        let view2 = UIView(frame: CGRect(x: 140, y: 20, width: 100, height: 100), accessibilityIdentifier: "myID")
        rootViewController.view.addSubview(view2)

        let trait = try XCTUnwrap(AppcuesTargetElementTrait(appcues: appcues, selector: ["accessibilityIdentifier":"myID"]))

        // Act/Assert
        XCTAssertThrowsError(try trait.decorate(backdropView: backdropView)) {
            XCTAssertEqual(($0 as? AppcuesTraitError)?.description, #"multiple non-distinct views (2) matched selector ["accessibilityIdentifier": "myID"]"#)
        }
    }

    func testDecorate() throws {
        // Arrange
        try XCTUnwrap(Appcues.elementTargeting as? UIKitElementTargeting).window = window

        let view1 = UIView(frame: CGRect(x: 20, y: 20, width: 100, height: 100), accessibilityIdentifier: "myID")
        rootViewController.view.addSubview(view1)

        let trait = try XCTUnwrap(AppcuesTargetElementTrait(appcues: appcues, selector: ["accessibilityIdentifier":"myID"]))
        trait.metadataDelegate = metadataDelegate

        // Act
        try trait.decorate(backdropView: backdropView)
        metadataDelegate.publish()

        // Assert
        XCTAssertEqual(metadataUpdates.count, 1)
        let latestMetadata = try XCTUnwrap(metadataUpdates.last)

        XCTAssertEqual(latestMetadata["targetRectangle"], CGRect(x: 20, y: 20, width: 100, height: 100))
    }

    func testDecorateMultipleMatches() throws {
        // Arrange
        try XCTUnwrap(Appcues.elementTargeting as? UIKitElementTargeting).window = window

        let view1 = UIView(frame: CGRect(x: 20, y: 20, width: 100, height: 100), accessibilityIdentifier: "myID", accessibilityLabel: "My View")
        rootViewController.view.addSubview(view1)
        let view2 = UIView(frame: CGRect(x: 140, y: 20, width: 100, height: 100), accessibilityIdentifier: "myID", tag: 54)
        rootViewController.view.addSubview(view2)

        let trait = try XCTUnwrap(AppcuesTargetElementTrait(appcues: appcues, selector: ["accessibilityIdentifier":"myID", "accessibilityLabel": "My View", "tag": "54"]))
        trait.metadataDelegate = metadataDelegate

        // Act
        try trait.decorate(backdropView: backdropView)
        metadataDelegate.publish()

        // Assert
        XCTAssertEqual(metadataUpdates.count, 1)
        let latestMetadata = try XCTUnwrap(metadataUpdates.last)

        XCTAssertEqual(latestMetadata["targetRectangle"], CGRect(x: 140, y: 20, width: 100, height: 100))
    }

    func testFrameRecalculation() throws {
        // Arrange
        try XCTUnwrap(Appcues.elementTargeting as? UIKitElementTargeting).window = window

        let view1 = UIView(frame: CGRect(x: 20, y: 20, width: 100, height: 100), accessibilityIdentifier: "myID")
        rootViewController.view.addSubview(view1)

        let trait = try XCTUnwrap(AppcuesTargetElementTrait(appcues: appcues, selector: ["accessibilityIdentifier":"myID"]))
        trait.metadataDelegate = metadataDelegate

        try trait.decorate(backdropView: backdropView)
        metadataDelegate.publish()

        // Act
        view1.frame = CGRect(x: 500, y: 20, width: 100, height: 100)
        window.frame = CGRect(x: 0, y: 0, width: 1000, height: 500)
        backdropView.frame = CGRect(x: 0, y: 0, width: 1000, height: 500)
        backdropView.setNeedsLayout()
        backdropView.layoutIfNeeded()

        // Assert
        XCTAssertEqual(metadataUpdates.count, 2)
        let latestMetadata = try XCTUnwrap(metadataUpdates.last)

        XCTAssertEqual(latestMetadata["targetRectangle"], CGRect(x: 500, y: 20, width: 100, height: 100))
    }

    func testUndecorate() throws {
        // Arrange
        try XCTUnwrap(Appcues.elementTargeting as? UIKitElementTargeting).window = window

        let view1 = UIView(frame: CGRect(x: 20, y: 20, width: 100, height: 100), accessibilityIdentifier: "myID")
        rootViewController.view.addSubview(view1)

        let trait = try XCTUnwrap(AppcuesTargetElementTrait(appcues: appcues, selector: ["accessibilityIdentifier":"myID"]))
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

extension UIView {
    convenience init(frame: CGRect, accessibilityIdentifier: String? = nil, accessibilityLabel: String? = nil, tag: Int? = nil) {
        self.init(frame: frame)
        self.accessibilityIdentifier = accessibilityIdentifier
        self.accessibilityLabel = accessibilityLabel
        if let tag = tag {
            self.tag = tag
        }
    }
}

@available(iOS 13.0, *)
extension AppcuesTargetElementTrait {
    convenience init?(
        appcues: Appcues?,
        selector: [String: String],
        contentPreferredPosition: ContentPosition? = nil,
        contentDistanceFromTarget: Double? = nil
    ) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(AppcuesTargetElementTrait.Config(
            contentPreferredPosition: contentPreferredPosition,
            contentDistanceFromTarget: contentDistanceFromTarget,
            selector: selector
        ), appcues: appcues))
    }
}
