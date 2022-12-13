//
//  PartialDictionaryDecodeTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2021-12-10.
//  Copyright © 2021 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class PartialDictionaryDecodeTests: XCTestCase {

    func testDecode() throws {
        // Arrange
        let data = #"""
        {
            "type": "@appcues/sticky-content",
            "config": {
                "edge": "bottom",
                "content": {
                    "type": "stack",
                    "id": "a4ac4eb8-f833-4be1-8b14-d58562f11aa8",
                    "orientation": "horizontal",
                    "distribution": "equal",
                    "items": [
                        {
                            "type": "block",
                            "blockType": "button",
                            "id": "f4c4f89e-4c8a-4c9d-9a8a-80c8bbfa8fa7",
                            "content": {
                                "type": "button",
                                "id": "c34f7d02-443d-497c-ac3a-1a9b42af9dd8",
                                "content": {
                                    "type": "text",
                                    "id": "6a43a477-7fc1-475e-998a-9b33ef6ad481",
                                    "text": "Button 1",
                                    "style": {
                                        "fontName": "Lato-Bold",
                                        "fontSize": 17,
                                        "foregroundColor": { "light": "#fff" }
                                    }
                                },
                                "style": {
                                    "marginTop": 20,
                                    "marginBottom": 20,
                                    "paddingTop": 8,
                                    "paddingLeading": 18,
                                    "paddingBottom": 8,
                                    "paddingTrailing": 18,
                                    "backgroundGradient": {
                                        "colors": [{ "light": "#5C5CFF" }, { "light": "#8960FF" }],
                                        "startPoint": "leading",
                                        "endPoint": "trailing"
                                    },
                                    "cornerRadius": 6,
                                    "shadow": {
                                        "color": { "light": "#777777ee" },
                                        "radius": 3,
                                        "x": 0,
                                        "y": 2
                                    }
                                }
                            }
                        }
                    ]
                }
            }
        }
        """#.data(using: .utf8)!

        // Act
        let trait = try JSONDecoder().decode(Experience.Trait.self, from: data)

        // Assert
        XCTAssertEqual(trait.type, "@appcues/sticky-content")
        let config = DecodingExperienceConfig(trait.config)
        XCTAssertEqual(config["edge"], "bottom")
        let content: ExperienceComponent = try XCTUnwrap(config["content"])
        XCTAssertNotNil(content)
    }
}
