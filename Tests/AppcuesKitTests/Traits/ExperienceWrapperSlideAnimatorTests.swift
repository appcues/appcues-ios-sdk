//
//  ExperienceWrapperSlideAnimatorTests.swift
//  AppcuesKitTests
//
//  Created by James Ellis on 9/12/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

import XCTest
@testable import AppcuesKit

@available(iOS 13.0, *)
class ExperienceWrapperSlideAnimatorTests: XCTestCase {

    private static let iPhone14ProPortraitFrame = CGRect(x: 0, y: 0, width: 393, height: 852)

    func testTopTransform() throws {
        // Arrange
        let wrapperView = ExperienceWrapperView()
        wrapperView.shadowWrappingView.frame = CGRect(x: 50, y: 100, width: 200, height: 300)

        // Act
        wrapperView.slideTransform(edge: .top, containerBounds: Self.iPhone14ProPortraitFrame)

        // Assert
        XCTAssertEqual(
            wrapperView.contentWrapperView.transform,
            CGAffineTransform.identity.translatedBy(x: 0, y: -400)
        )
    }

    func testLeadingTransform() throws {
        // Arrange
        let wrapperView = ExperienceWrapperView()
        wrapperView.shadowWrappingView.frame = CGRect(x: 50, y: 100, width: 200, height: 300)

        // Act
        wrapperView.slideTransform(edge: .leading, containerBounds: Self.iPhone14ProPortraitFrame)

        // Assert
        XCTAssertEqual(
            wrapperView.contentWrapperView.transform,
            CGAffineTransform.identity.translatedBy(x: -250, y: 0
            )
        )
    }

    func testBottomTransform() throws {
        // Arrange
        let wrapperView = ExperienceWrapperView()
        wrapperView.shadowWrappingView.frame = CGRect(x: 50, y: 100, width: 200, height: 300)

        // Act
        wrapperView.slideTransform(edge: .bottom, containerBounds: Self.iPhone14ProPortraitFrame)

        // Assert
        XCTAssertEqual(
            wrapperView.contentWrapperView.transform,
            CGAffineTransform.identity.translatedBy(x: 0, y: 752)
        )
    }

    func testTrailingTransform() throws {
        // Arrange
        let wrapperView = ExperienceWrapperView()
        wrapperView.shadowWrappingView.frame = CGRect(x: 50, y: 100, width: 200, height: 300)

        // Act
        wrapperView.slideTransform(edge: .trailing, containerBounds: Self.iPhone14ProPortraitFrame)

        // Assert
        XCTAssertEqual(
            wrapperView.contentWrapperView.transform,
            CGAffineTransform.identity.translatedBy(x: 343, y: 0)
        )
    }

    func testCenterTransform() throws {
        // Arrange
        let wrapperView = ExperienceWrapperView()
        wrapperView.shadowWrappingView.frame = CGRect(x: 50, y: 100, width: 200, height: 300)

        // Act
        wrapperView.slideTransform(edge: .center, containerBounds: Self.iPhone14ProPortraitFrame)

        // Assert
        XCTAssertEqual(
            wrapperView.contentWrapperView.transform,
            CGAffineTransform.identity.translatedBy(x: 0, y: 150)
        )
    }

}
