//
//  AppcuesModalTraitTests.swift
//  AppcuesKitTests
//
//  Created by James Ellis on 9/12/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

@available(iOS 13.0, *)
class AppcuesModalTraitTests: XCTestCase {


    func testTransitionConfig() throws {
        // Assert
        XCTAssertEqual(
            AppcuesModalTrait.Config(transition: "fade").toTransition(),
            .fade
        )
        XCTAssertEqual(
            AppcuesModalTrait.Config(transition: "slide").toTransition(),
            .slide(edge: .center)
        )
        XCTAssertEqual(
            AppcuesModalTrait.Config(transition: "slide", horizontalAlignment: "center").toTransition(),
            .slide(edge: .center)
        )
        XCTAssertEqual(
            AppcuesModalTrait.Config(transition: "slide", verticalAlignment: "center").toTransition(),
            .slide(edge: .center)
        )
        XCTAssertEqual(
            AppcuesModalTrait.Config(transition: "slide", horizontalAlignment: "center", verticalAlignment: "center").toTransition(),
            .slide(edge: .center)
        )
        XCTAssertEqual(
            AppcuesModalTrait.Config(transition: "slide", horizontalAlignment: "leading").toTransition(),
            .slide(edge: .leading)
        )
        XCTAssertEqual(
            AppcuesModalTrait.Config(transition: "slide", horizontalAlignment: "leading", verticalAlignment: "top").toTransition(),
            .slide(edge: .leading)
        )
        XCTAssertEqual(
            AppcuesModalTrait.Config(transition: "slide", horizontalAlignment: "leading", verticalAlignment: "center").toTransition(),
            .slide(edge: .leading)
        )
        XCTAssertEqual(
            AppcuesModalTrait.Config(transition: "slide", horizontalAlignment: "leading", verticalAlignment: "bottom").toTransition(),
            .slide(edge: .leading)
        )
        XCTAssertEqual(
            AppcuesModalTrait.Config(transition: "slide", horizontalAlignment: "trailing").toTransition(),
            .slide(edge: .trailing)
        )
        XCTAssertEqual(
            AppcuesModalTrait.Config(transition: "slide", horizontalAlignment: "trailing", verticalAlignment: "top").toTransition(),
            .slide(edge: .trailing)
        )
        XCTAssertEqual(
            AppcuesModalTrait.Config(transition: "slide", horizontalAlignment: "trailing", verticalAlignment: "center").toTransition(),
            .slide(edge: .trailing)
        )
        XCTAssertEqual(
            AppcuesModalTrait.Config(transition: "slide", horizontalAlignment: "trailing", verticalAlignment: "bottom").toTransition(),
            .slide(edge: .trailing)
        )
        XCTAssertEqual(
            AppcuesModalTrait.Config(transition: "slide", verticalAlignment: "top").toTransition(),
            .slide(edge: .top)
        )
        XCTAssertEqual(
            AppcuesModalTrait.Config(transition: "slide", horizontalAlignment: "center", verticalAlignment: "top").toTransition(),
            .slide(edge: .top)
        )
        XCTAssertEqual(
            AppcuesModalTrait.Config(transition: "slide", verticalAlignment: "bottom").toTransition(),
            .slide(edge: .bottom)
        )
        XCTAssertEqual(
            AppcuesModalTrait.Config(transition: "slide", horizontalAlignment: "center", verticalAlignment: "bottom").toTransition(),
            .slide(edge: .bottom)
        )
    }
}

@available(iOS 13.0, *)
extension AppcuesModalTrait.Config {
    init(
        transition: String,
        horizontalAlignment: String? = nil,
        verticalAlignment: String? = nil
    ) {
        self.init(
            presentationStyle: .dialog,
            style: ExperienceComponent.Style(
                verticalAlignment: verticalAlignment,
                horizontalAlignment: horizontalAlignment,
                paddingTop: nil,
                paddingLeading: nil,
                paddingBottom: nil,
                paddingTrailing: nil,
                marginTop: nil,
                marginLeading: nil,
                marginBottom: nil,
                marginTrailing: nil,
                height: nil,
                width: nil,
                fontName: nil,
                fontSize: nil,
                letterSpacing: nil,
                lineHeight: nil,
                textAlignment: nil,
                foregroundColor: nil,
                backgroundColor: nil,
                backgroundGradient: nil,
                backgroundImage: nil,
                shadow: nil,
                cornerRadius: nil,
                borderColor: nil,
                borderWidth: nil
            ),
            transition: transition
        )
    }


}
