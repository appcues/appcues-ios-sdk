//
//  AppcuesTargetElementTraitTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2023-05-16.
//  Copyright © 2023 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class AppcuesTargetElementTraitTests: XCTestCase {

    var appcues: MockAppcues!

    let metadataDelegate = AppcuesTraitMetadataDelegate()
    var metadataUpdates: [AppcuesTraitMetadata] = []

    var window: UIWindow!
    var rootViewController: UIViewController!
    var backdropView: UIView!
    var safeArea: CGRect!

    @MainActor
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

        safeArea = rootViewController.view.bounds.inset(by: rootViewController.view.safeAreaInsets)
    }

    override func tearDownWithError() throws {
        try XCTUnwrap(Appcues.elementTargeting as? UIKitElementTargeting).window = nil
    }

    @MainActor
    func testInit() throws {
        // Act
        let nilConfigTrait = AppcuesTargetElementTrait(configuration: AppcuesExperiencePluginConfiguration(nil))
        let trait = AppcuesTargetElementTrait(appcues: appcues, selector: [:])

        // Assert
        XCTAssertEqual(AppcuesTargetElementTrait.type, "@appcues/target-element")
        XCTAssertNil(nilConfigTrait)
        XCTAssertNotNil(trait)
    }

    @MainActor
    func testDecorateThrowsInvalidSelector() async throws {
        // Arrange
        let trait = try XCTUnwrap(AppcuesTargetElementTrait(appcues: appcues, selector: [:]))

        // Act/Assert
        await XCTAssertThrowsAsyncError(try await trait.decorate(backdropView: backdropView)) {
            XCTAssertEqual(($0 as? AppcuesTraitError)?.description, "Invalid selector [:]")
        }
    }

    @MainActor
    func testDecorateThrowsNoLayout() async throws {
        // Arrange
        let trait = try XCTUnwrap(AppcuesTargetElementTrait(appcues: appcues, selector: ["accessibilityIdentifier":"myID"]))

        // Act/Assert
        await XCTAssertThrowsAsyncError(try await trait.decorate(backdropView: backdropView)) {
            XCTAssertEqual(($0 as? AppcuesTraitError)?.description, "Could not read application layout information")
        }
    }

    @MainActor
    func testDecorateThrowsNoMatch() async throws {
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
        await XCTAssertThrowsAsyncError(try await trait.decorate(backdropView: backdropView)) {
            XCTAssertEqual(($0 as? AppcuesTraitError)?.description, #"No view matching selector ["accessibilityIdentifier": "myID"]"#)
        }
    }

    @MainActor
    func testDecorateThrowsMultipleMatch() async throws {
        // Arrange
        try XCTUnwrap(Appcues.elementTargeting as? UIKitElementTargeting).window = window

        let view1 = UIView(frame: CGRect(x: 20, y: 20, width: 100, height: 100), accessibilityIdentifier: "myID")
        rootViewController.view.addSubview(view1)
        let view2 = UIView(frame: CGRect(x: 140, y: 20, width: 100, height: 100), accessibilityIdentifier: "myID")
        rootViewController.view.addSubview(view2)

        let trait = try XCTUnwrap(AppcuesTargetElementTrait(appcues: appcues, selector: ["accessibilityIdentifier":"myID"]))

        // Act/Assert
        await XCTAssertThrowsAsyncError(try await trait.decorate(backdropView: backdropView)) {
            XCTAssertEqual(($0 as? AppcuesTraitError)?.description, #"multiple non-distinct views (2) matched selector ["accessibilityIdentifier": "myID"]"#)
        }
    }

    @MainActor
    func testDecorate() async throws {
        // Arrange
        try XCTUnwrap(Appcues.elementTargeting as? UIKitElementTargeting).window = window

        let frame = CGRect(x: 20, y: 20, width: 100, height: 100)
        let view1 = UIView(frame: frame, accessibilityIdentifier: "myID")
        rootViewController.view.addSubview(view1)

        let trait = try XCTUnwrap(AppcuesTargetElementTrait(appcues: appcues, selector: ["accessibilityIdentifier":"myID"]))
        trait.metadataDelegate = metadataDelegate

        // Act
        try await trait.decorate(backdropView: backdropView)
        metadataDelegate.publish()

        // Assert
        XCTAssertEqual(metadataUpdates.count, 1)
        let latestMetadata = try XCTUnwrap(metadataUpdates.last)

        XCTAssertEqual(latestMetadata["targetRectangle"], safeArea.intersection(frame))
    }

    @MainActor
    func testDecorateMultipleMatches() async throws {
        // Arrange
        try XCTUnwrap(Appcues.elementTargeting as? UIKitElementTargeting).window = window

        let frame1 = CGRect(x: 20, y: 20, width: 100, height: 100)
        let view1 = UIView(frame: frame1, accessibilityIdentifier: "myID", accessibilityLabel: "My View")
        rootViewController.view.addSubview(view1)
        let frame2 = CGRect(x: 140, y: 20, width: 100, height: 100)
        let view2 = UIView(frame: frame2, accessibilityIdentifier: "myID", tag: 54)
        rootViewController.view.addSubview(view2)

        let trait = try XCTUnwrap(AppcuesTargetElementTrait(appcues: appcues, selector: ["accessibilityIdentifier":"myID", "accessibilityLabel": "My View", "tag": "54"]))
        trait.metadataDelegate = metadataDelegate

        // Act
        try await trait.decorate(backdropView: backdropView)
        metadataDelegate.publish()

        // Assert
        XCTAssertEqual(metadataUpdates.count, 1)
        let latestMetadata = try XCTUnwrap(metadataUpdates.last)

        XCTAssertEqual(latestMetadata["targetRectangle"], safeArea.intersection(frame2))
    }

    @MainActor
    func testFrameRecalculation() async throws {
        // Arrange
        let metadataExpectation = expectation(description: "metadata received")
        metadataExpectation.expectedFulfillmentCount = 2
        metadataDelegate.registerHandler(for: "wait", animating: false) { metadata in
            metadataExpectation.fulfill()
        }

        try XCTUnwrap(Appcues.elementTargeting as? UIKitElementTargeting).window = window

        let view1 = UIView(frame: CGRect(x: 20, y: 20, width: 100, height: 100), accessibilityIdentifier: "myID")
        rootViewController.view.addSubview(view1)

        let trait = try XCTUnwrap(AppcuesTargetElementTrait(appcues: appcues, selector: ["accessibilityIdentifier":"myID"]))
        trait.metadataDelegate = metadataDelegate

        try await trait.decorate(backdropView: backdropView)
        metadataDelegate.publish()

        let updatedFrame = CGRect(x: 500, y: 20, width: 100, height: 100)

        // Act
        view1.frame = updatedFrame
        window.frame = CGRect(x: 0, y: 0, width: 1000, height: 500)
        backdropView.frame = CGRect(x: 0, y: 0, width: 1000, height: 500)
        backdropView.setNeedsLayout()
        backdropView.layoutIfNeeded()

        // Assert
        await fulfillment(of: [metadataExpectation], timeout: 1)
        XCTAssertEqual(metadataUpdates.count, 2)
        let latestMetadata = try XCTUnwrap(metadataUpdates.last)

        let updatedSafeArea = rootViewController.view.bounds.inset(by: rootViewController.view.safeAreaInsets)
        XCTAssertEqual(latestMetadata["targetRectangle"], updatedSafeArea.intersection(updatedFrame))
    }

    @MainActor
    func testUndecorate() async throws {
        // Arrange
        try XCTUnwrap(Appcues.elementTargeting as? UIKitElementTargeting).window = window

        let view1 = UIView(frame: CGRect(x: 20, y: 20, width: 100, height: 100), accessibilityIdentifier: "myID")
        rootViewController.view.addSubview(view1)

        let trait = try XCTUnwrap(AppcuesTargetElementTrait(appcues: appcues, selector: ["accessibilityIdentifier":"myID"]))
        trait.metadataDelegate = metadataDelegate

        try await trait.decorate(backdropView: backdropView)
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

    @MainActor
    func testElementDisplayName() async throws {
        let frame = CGRect(x: 20, y: 20, width: 100, height: 100)

        let view1 = UIView(frame: frame)
        view1.accessibilityIdentifier = "myAccessibilityID"
        let view1Element = await view1.asViewElement()
        XCTAssertEqual(view1Element?.displayName, "myAccessibilityID")

        let view2 = AppcuesTargetView(identifier: "someID")
        view2.frame = frame
        let view2Element = await view2.asViewElement()
        XCTAssertEqual(view2Element?.displayName, "someID")

        let view3 = UIView(frame: frame)
        view3.tag = 226
        let view3Element = await view3.asViewElement()
        XCTAssertEqual(view3Element?.displayName, "UIView (tag 226)")

        let view4 = UIButton(frame: frame)
        view4.accessibilityLabel = "My Button"
        let view4Element = await view4.asViewElement()
        XCTAssertEqual(view4Element?.displayName, "UIButton (My Button)")

        let view5 = UIView(frame: frame)
        let view5Element = await view5.asViewElement()
        XCTAssertNil(view5Element?.displayName)
    }

    func testEmptySelectorValues() throws {
        // empty string values for selector properties
        // should be stripped out and made nil, resulting in no selector
        let selector = UIKitElementSelector(
            appcuesID: "",
            accessibilityIdentifier: "",
            accessibilityLabel: "",
            tag: "",
            autoTag: ""
        )
        XCTAssertNil(selector)
    }

    @MainActor
    func testTabBarDisplayName() async throws {
        let frame = CGRect(x: 20, y: 20, width: 100, height: 100)
        
        let tabBarView = UITabBar(frame: frame)
        let tabBarButton1 = UITabBarButton()
        let tabBarButton2 = UITabBarButton()
        let tabBarButton3 = UITabBarButton()
        tabBarView.addSubview(tabBarButton1)
        tabBarView.addSubview(tabBarButton2)
        tabBarView.addSubview(UIView()) //should be ignored
        tabBarView.addSubview(UIView()) //should be ignored
        tabBarView.addSubview(tabBarButton3)

        let tabBarViewElement = await tabBarView.asViewElement()
        XCTAssertNil(tabBarViewElement?.displayName)

        let tabBarChildren = try XCTUnwrap(tabBarViewElement?.children)
        XCTAssertEqual(tabBarChildren[0].displayName, "tab[0]")
        XCTAssertEqual(tabBarChildren[1].displayName, "tab[1]")
        XCTAssertNil(tabBarChildren[2].displayName)
        XCTAssertNil(tabBarChildren[3].displayName)
        XCTAssertEqual(tabBarChildren[4].displayName, "tab[2]")
    }

    @MainActor
    func testTabBarDecorate() async throws {
        // Arrange
        try XCTUnwrap(Appcues.elementTargeting as? UIKitElementTargeting).window = window

        // tab bar needs to be inside the safe area
        let tabBarView = UITabBar()
        let tabBarButton1 = UITabBarButton()
        let tabBarButton2 = UITabBarButton()
        // this button is inside the tab bar
        let tabBarButton3 = UITabBarButton(frame: CGRect(x: 10, y: 100, width: 40, height: 40))
        tabBarView.addSubview(tabBarButton1)
        tabBarView.addSubview(tabBarButton2)
        tabBarView.addSubview(UIView()) //should be ignored
        tabBarView.addSubview(UIView()) //should be ignored
        tabBarView.addSubview(tabBarButton3)

        rootViewController.view.addSubview(tabBarView)

        let trait = try XCTUnwrap(AppcuesTargetElementTrait(appcues: appcues, selector: ["autoTag":"tab[2]"]))
        trait.metadataDelegate = metadataDelegate

        // Act
        try await trait.decorate(backdropView: backdropView)
        metadataDelegate.publish()

        // Assert
        XCTAssertEqual(metadataUpdates.count, 1)
        let latestMetadata = try XCTUnwrap(metadataUpdates.last)

        // the rect here is x/y positioned relative to button 3 offset within the tab bar frame
        XCTAssertEqual(latestMetadata["targetRectangle"], CGRect(x: 10, y: 100, width: 40, height: 40))
    }
}

// mimicking the internal UITabBarButton used inside of UITabBar subviews for testing
class UITabBarButton: UIView {

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

extension AppcuesTargetElementTrait {
    convenience init?(
        appcues: Appcues?,
        selector: [String: String],
        contentPreferredPosition: ContentPosition? = nil,
        contentDistanceFromTarget: Double? = nil,
        retryIntervals: [Int]? = nil
    ) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(AppcuesTargetElementTrait.Config(
            contentPreferredPosition: contentPreferredPosition,
            contentDistanceFromTarget: contentDistanceFromTarget,
            selector: selector,
            retryIntervals: retryIntervals
        ), appcues: appcues))
    }
}
