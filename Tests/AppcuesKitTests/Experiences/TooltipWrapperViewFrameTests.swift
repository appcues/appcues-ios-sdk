//
//  TooltipWrapperViewFrameTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2023-03-03.
//  Copyright © 2023 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class TooltipWrapperViewFrameTests: XCTestCase {

    private static let iPhone14ProPortraitFrame = CGRect(x: 0, y: 0, width: 393, height: 852)
    private static let iPhone14ProLandscapeFrame = CGRect(x: 0, y: 0, width: 852, height: 393)
    private static let iPadPro12PortraitFrame = CGRect(x: 0, y: 0, width: 1024, height: 1366)

    var view: TooltipWrapperView!

    override func setUpWithError() throws {
        view = TooltipWrapperView()
    }

    // MARK: - No Target Rectangle

    func testNoTargetRectangleDefaultFrame() {
        // Arrange
        view.frame = Self.iPhone14ProPortraitFrame
        view.preferredWidth = nil
        view.preferredPosition = nil
        view.pointerSize = nil
        view.distanceFromTarget = 0
        view.targetRectangle = nil
        view.preferredContentSize = nil

        // Act
        view.positionContentView()

        // Assert
        XCTAssertEqual(
            view.shadowWrappingView.frame,
            CGRect(x: 8, y: 552, width: 377, height: 300),
            "Inside the layout margins and at the bottom of the screen"
        )
    }

    func testNoTargetRectangleTooltipStyling() {
        // Arrange
        view.frame = Self.iPhone14ProPortraitFrame
        view.targetRectangle = nil
        view.preferredWidth = 200
        view.preferredPosition = .top
        view.pointerSize = CGSize(width: 10, height: 20)
        view.distanceFromTarget = 10
        view.preferredContentSize = nil

        // Act
        view.positionContentView()

        // Assert
        XCTAssertEqual(
            view.shadowWrappingView.frame,
            CGRect(x: 8, y: 552, width: 377, height: 300),
            "Tooltip layout options are ignored when no target rectangle"
        )
    }

    func testNoTargetRectangleFrameHeight() {
        // Arrange
        view.frame = Self.iPhone14ProPortraitFrame
        view.targetRectangle = nil
        view.preferredWidth = nil
        view.preferredPosition = nil
        view.pointerSize = nil
        view.distanceFromTarget = 0
        view.preferredContentSize = CGSize(width: 337, height: 416)

        // Act
        view.positionContentView()

        // Assert
        XCTAssertEqual(
            view.shadowWrappingView.frame,
            CGRect(x: 8, y: 436, width: 377, height: 416),
            "Frame scales with preferred content height"
        )
    }

    func testFrameHeightCappedWhenNoTargetRectangle() {
        // Arrange
        view.frame = Self.iPhone14ProPortraitFrame
        view.targetRectangle = nil
        view.preferredWidth = nil
        view.preferredPosition = nil
        view.pointerSize = nil
        view.distanceFromTarget = 0
        view.preferredContentSize = CGSize(width: 337, height: 2000)

        // Act
        view.positionContentView()

        // Assert
        // The test setup has no safe areas, so the height will be capped at the view height
        XCTAssertEqual(
            view.shadowWrappingView.frame,
            CGRect(x: 8, y: 0, width: 377, height: 852),
            "Frame height is capped"
        )
    }

    // MARK: Bottom Position

    func testPreferredBottomDefaults() {
        // Arrange
        view.frame = Self.iPadPro12PortraitFrame
        view.targetRectangle = CGRect(x: 500, y: 600, width: 38, height: 42)
        view.preferredWidth = nil
        view.preferredPosition = .bottom
        view.pointerSize = nil
        view.distanceFromTarget = 0
        view.preferredContentSize = nil

        // Act
        view.positionContentView()

        // Assert
        XCTAssertEqual(view.shadowWrappingView.frame.width, 400, "Takes the unspecified max width")
        XCTAssertEqual(view.shadowWrappingView.frame.height, 46, "Takes the minimum height")
        XCTAssertEqual(view.shadowWrappingView.frame.origin.x, 319, "Centered horizontally on the target") // 500+38/2-400/2
        XCTAssertEqual(view.shadowWrappingView.frame.origin.y, 642, "Below the target") // 600+42
    }

    func testPreferredBottomStyled() {
        // Arrange
        view.frame = Self.iPadPro12PortraitFrame
        view.targetRectangle = CGRect(x: 500, y: 600, width: 38, height: 42)
        view.preferredWidth = 220
        view.preferredPosition = .bottom
        view.pointerSize = CGSize(width: 12, height: 24)
        view.distanceFromTarget = 15
        view.preferredContentSize = CGSize(width: 220, height: 226)

        // Act
        view.positionContentView()

        // Assert
        XCTAssertEqual(view.shadowWrappingView.frame.width, 220, "Takes the preferred width")
        XCTAssertEqual(view.shadowWrappingView.frame.height, 250, "Takes the content height plus the pointer length") // 226+24
        XCTAssertEqual(view.shadowWrappingView.frame.origin.x, 409, "Centered horizontally on the target") // 500+38/2-220/2
        XCTAssertEqual(view.shadowWrappingView.frame.origin.y, 657, "Below the target with specified distance") // 600+42+15
    }

    // MARK: Top Position

    func testPreferredTopDefaults() {
        // Arrange
        view.frame = Self.iPadPro12PortraitFrame
        view.targetRectangle = CGRect(x: 500, y: 600, width: 38, height: 42)
        view.preferredWidth = nil
        view.preferredPosition = .top
        view.pointerSize = nil
        view.distanceFromTarget = 0
        view.preferredContentSize = nil

        // Act
        view.positionContentView()

        // Assert
        XCTAssertEqual(view.shadowWrappingView.frame.width, 400, "Takes the unspecified max width")
        XCTAssertEqual(view.shadowWrappingView.frame.height, 46, "Takes the minimum height")
        XCTAssertEqual(view.shadowWrappingView.frame.origin.x, 319, "Centered horizontally on the target") // 500+38/2-400/2
        XCTAssertEqual(view.shadowWrappingView.frame.origin.y, 554, "Above the target") // 600-46
    }

    func testPreferredTopStyled() {
        // Arrange
        view.frame = Self.iPadPro12PortraitFrame
        view.targetRectangle = CGRect(x: 500, y: 600, width: 38, height: 42)
        view.preferredWidth = 220
        view.preferredPosition = .top
        view.pointerSize = CGSize(width: 12, height: 24)
        view.distanceFromTarget = 15
        view.preferredContentSize = CGSize(width: 220, height: 226)

        // Act
        view.positionContentView()

        // Assert
        XCTAssertEqual(view.shadowWrappingView.frame.width, 220, "Takes the preferred width")
        XCTAssertEqual(view.shadowWrappingView.frame.height, 250, "Takes the content height plus the pointer length") // 226+24
        XCTAssertEqual(view.shadowWrappingView.frame.origin.x, 409, "Centered horizontally on the target") // 500+38/2-220/2
        XCTAssertEqual(view.shadowWrappingView.frame.origin.y, 335, "Above the target with specified distance") // 600-(226+24)-15
    }

    // MARK: Leading Position
    func testPreferredLeadingDefaults() {
        // Arrange
        view.frame = Self.iPadPro12PortraitFrame
        view.targetRectangle = CGRect(x: 500, y: 600, width: 38, height: 42)
        view.preferredWidth = nil
        view.preferredPosition = .leading
        view.pointerSize = nil
        view.distanceFromTarget = 0
        view.preferredContentSize = nil

        // Act
        view.positionContentView()

        // Assert
        XCTAssertEqual(view.shadowWrappingView.frame.width, 400, "Takes the unspecified max width")
        XCTAssertEqual(view.shadowWrappingView.frame.height, 46, "Takes the minimum height")
        XCTAssertEqual(view.shadowWrappingView.frame.origin.x, 100, "Before the target") // 500-400
        XCTAssertEqual(view.shadowWrappingView.frame.origin.y, 598, "Centered vertically on the target") // 600+42/2-46/2
    }

    func testPreferredLeadingStyled() {
        // Arrange
        view.frame = Self.iPadPro12PortraitFrame
        view.targetRectangle = CGRect(x: 500, y: 600, width: 38, height: 42)
        view.preferredWidth = 220
        view.preferredPosition = .leading
        view.pointerSize = CGSize(width: 12, height: 24)
        view.distanceFromTarget = 15
        view.preferredContentSize = CGSize(width: 220, height: 226)

        // Act
        view.positionContentView()

        // Assert
        XCTAssertEqual(view.shadowWrappingView.frame.width, 244, "Takes the preferred width plus the pointer length") // 220+24
        XCTAssertEqual(view.shadowWrappingView.frame.height, 226, "Takes the content height")
        XCTAssertEqual(view.shadowWrappingView.frame.origin.x, 241, "Before the target with specified distance") // 500-(220+24)-15
        XCTAssertEqual(view.shadowWrappingView.frame.origin.y, 508, "Centered vertically on the target") // 600+42/2-226/2
    }

    // MARK: Trailing Position
    func testPreferredTrailingDefaults() {
        // Arrange
        view.frame = Self.iPadPro12PortraitFrame
        view.targetRectangle = CGRect(x: 500, y: 600, width: 38, height: 42)
        view.preferredWidth = nil
        view.preferredPosition = .trailing
        view.pointerSize = nil
        view.distanceFromTarget = 0
        view.preferredContentSize = nil

        // Act
        view.positionContentView()

        // Assert
        XCTAssertEqual(view.shadowWrappingView.frame.width, 400, "Takes the unspecified max width")
        XCTAssertEqual(view.shadowWrappingView.frame.height, 46, "Takes the minimum height")
        XCTAssertEqual(view.shadowWrappingView.frame.origin.x, 538, "After the target") // 500+38
        XCTAssertEqual(view.shadowWrappingView.frame.origin.y, 598, "Centered vertically on the target") // 600+42/2-46/2
    }

    func testPreferredTrailingStyled() {
        // Arrange
        view.frame = Self.iPadPro12PortraitFrame
        view.targetRectangle = CGRect(x: 500, y: 600, width: 38, height: 42)
        view.preferredWidth = 220
        view.preferredPosition = .trailing
        view.pointerSize = CGSize(width: 12, height: 24)
        view.distanceFromTarget = 15
        view.preferredContentSize = CGSize(width: 220, height: 226)

        // Act
        view.positionContentView()

        // Assert
        XCTAssertEqual(view.shadowWrappingView.frame.width, 244, "Takes the preferred width plus the pointer length") // 220+24
        XCTAssertEqual(view.shadowWrappingView.frame.height, 226, "Takes the content height")
        XCTAssertEqual(view.shadowWrappingView.frame.origin.x, 553, "After the target with specified distance") // 500+38+15
        XCTAssertEqual(view.shadowWrappingView.frame.origin.y, 508, "Centered vertically on the target") // 600+42/2-226/2
    }

    // MARK: Adjusted Positioning

    func testPositionAutomaticallySetToTop() {
        // Arrange
        view.frame = Self.iPhone14ProPortraitFrame
        view.targetRectangle = CGRect(x: 100, y: 600, width: 192, height: 64)
        view.preferredWidth = 220
        view.preferredPosition = nil
        view.pointerSize = nil
        view.distanceFromTarget = 0
        view.preferredContentSize = nil

        // Act
        view.positionContentView()

        // Assert
        XCTAssertEqual(view.shadowWrappingView.frame.width, 220, "Takes the preferred width")
        XCTAssertEqual(view.shadowWrappingView.frame.height, 46, "Takes the minimum height")
        XCTAssertEqual(view.shadowWrappingView.frame.origin.x, 86, "Centered horizontally on the target") // 100+192/2-220/2
        XCTAssertEqual(view.shadowWrappingView.frame.origin.y, 554, "Above the target") // 600-46
    }

    func testPositionAutomaticallySetToBottom() {
        // Arrange
        view.frame = Self.iPhone14ProPortraitFrame
        view.targetRectangle = CGRect(x: 100, y: 200, width: 192, height: 64)
        view.preferredWidth = 220
        view.preferredPosition = nil
        view.pointerSize = nil
        view.distanceFromTarget = 0
        view.preferredContentSize = nil

        // Act
        view.positionContentView()

        // Assert
        XCTAssertEqual(view.shadowWrappingView.frame.width, 220, "Takes the preferred width")
        XCTAssertEqual(view.shadowWrappingView.frame.height, 46, "Takes the minimum height")
        XCTAssertEqual(view.shadowWrappingView.frame.origin.x, 86, "Centered horizontally on the target") // 100+192/2-220/2
        XCTAssertEqual(view.shadowWrappingView.frame.origin.y, 264, "Below the target") // 200+64
    }

    func testPositionAutomaticallySetToLeading() {
        // Arrange
        view.frame = Self.iPhone14ProLandscapeFrame
        view.targetRectangle = CGRect(x: 600, y: 24, width: 192, height: 344)
        view.preferredWidth = 220
        view.preferredPosition = nil
        view.pointerSize = nil
        view.distanceFromTarget = 0
        view.preferredContentSize = nil

        // Act
        view.positionContentView()

        // Assert
        XCTAssertEqual(view.shadowWrappingView.frame.width, 220, "Takes the preferred width")
        XCTAssertEqual(view.shadowWrappingView.frame.height, 46, "Takes the minimum height")
        XCTAssertEqual(view.shadowWrappingView.frame.origin.x, 380, "Before the target") // 600-220
        XCTAssertEqual(view.shadowWrappingView.frame.origin.y, 173, "Centered vertically on the target") // 24+344/2-46/2
    }

    func testPositionAutomaticallySetToTrailing() {
        // Arrange
        view.frame = Self.iPhone14ProLandscapeFrame
        view.targetRectangle = CGRect(x: 100, y: 24, width: 192, height: 344)
        view.preferredWidth = 220
        view.preferredPosition = nil
        view.pointerSize = nil
        view.distanceFromTarget = 0
        view.preferredContentSize = nil

        // Act
        view.positionContentView()

        // Assert
        XCTAssertEqual(view.shadowWrappingView.frame.width, 220, "Takes the preferred width")
        XCTAssertEqual(view.shadowWrappingView.frame.height, 46, "Takes the minimum height")
        XCTAssertEqual(view.shadowWrappingView.frame.origin.x, 292, "After the target") // 100+192
        XCTAssertEqual(view.shadowWrappingView.frame.origin.y, 173, "Centered vertically on the target") // 24+344/2-46/2
    }

    func testPositionAutomaticallySetToBottomWhenNoFit() {
        // Arrange
        view.frame = Self.iPhone14ProPortraitFrame
        view.targetRectangle = CGRect(x: 0, y: 0, width: 392, height: 842)
        view.preferredWidth = 220
        view.preferredPosition = nil
        view.pointerSize = nil
        view.distanceFromTarget = 0
        view.preferredContentSize = nil

        // Act
        view.positionContentView()

        // Assert
        XCTAssertEqual(view.shadowWrappingView.frame.width, 220, "Takes the preferred width")
        XCTAssertEqual(view.shadowWrappingView.frame.height, 46, "Takes the minimum height")
        XCTAssertEqual(view.shadowWrappingView.frame.origin.x, 86, "Centered horizontally on the target") // 0+392/2-220/2
        XCTAssertEqual(view.shadowWrappingView.frame.origin.y, 798, "Below (but overlapping) the target, but inside the safe area") // 852-8-46
    }

    func testPositionAutomaticallySetToTopWhenNoFit() {
        // Arrange
        view.frame = Self.iPhone14ProPortraitFrame
        view.targetRectangle = CGRect(x: 0, y: 10, width: 392, height: 842)
        view.preferredWidth = 220
        view.preferredPosition = nil
        view.pointerSize = nil
        view.distanceFromTarget = 0
        view.preferredContentSize = nil

        // Act
        view.positionContentView()

        // Assert
        XCTAssertEqual(view.shadowWrappingView.frame.width, 220, "Takes the preferred width")
        XCTAssertEqual(view.shadowWrappingView.frame.height, 46, "Takes the minimum height")
        XCTAssertEqual(view.shadowWrappingView.frame.origin.x, 86, "Centered horizontally on the target") // 0+392/2-220/2
        XCTAssertEqual(view.shadowWrappingView.frame.origin.y, 8, "Above (but overlapping) the target, but inside the safe area")
    }

}
