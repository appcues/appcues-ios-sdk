//
//  TraitConfigurationDecodeTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2021-12-10.
//  Copyright © 2021 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

@available(iOS 13.0, *)
class TraitConfigurationDecodeTests: XCTestCase {

    func testDecode() throws {
        // Arrange
        let data = #"""
        {
            "type": "@appcues/modal",
            "config": {
                "presentationStyle": "dialog",
                "style": {
                    "cornerRadius": 8,
                    "backgroundColor": { "light": "#ffffff", "dark": "#000000" },
                    "shadow": {
                        "color": { "light": "#777777ee" },
                        "radius": 3,
                        "x": 0,
                        "y": 2
                    }
                }
            }
        }
        """#.data(using: .utf8)!

        // Act
        let trait = try JSONDecoder().decode(Experience.Trait.self, from: data)

        // Assert
        XCTAssertEqual(trait.type, "@appcues/modal")
        let decoder = trait.configDecoder
        let config = try XCTUnwrap(decoder.decode(AppcuesModalTrait.Config.self))
        XCTAssertEqual(config.presentationStyle, .dialog)
        XCTAssertEqual(config.style?.cornerRadius, 8)
    }
}
