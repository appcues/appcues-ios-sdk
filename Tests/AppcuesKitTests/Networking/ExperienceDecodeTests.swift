//
//  ExperienceDecodeTests.swift
//  AppcuesKitTests
//
//  Created by James Ellis on 12/9/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation
import XCTest
@testable import AppcuesKit

class ExperienceDecodeTests: XCTestCase {

    func testValid() throws {
        // Arrange
        let data = #"""
        {
            "id": "05e78601-d7d8-449f-a074-fe3ae1144366",
            "name": "basic valid experience",
            "type": "mobile",
            "traits": [],
            "steps": [
                {
                    "id": "f7edb07c-5f96-4440-9b70-3bdd0b7675b0",
                    "type": "group",
                    "actions": {},
                    "traits": [
                        {
                            "type": "group-trait",
                            "config": {
                                "key": "value"
                            }
                        }
                    ],
                    "children": [
                        {
                            "id": "68bb5cc4-99b4-4f5c-a787-930ba921fc05",
                            "type": "modal",
                            "content": {
                                "type": "spacer",
                                "id": "1f9d1c11-525f-4f1c-afc1-d91b97c6a7d4"
                            },
                            "traits": [
                                {
                                    "type": "step-trait",
                                    "config": {
                                        "prop": 1
                                    }
                                }
                            ],
                            "actions": {
                                "1f9d1c11-525f-4f1c-afc1-d91b97c6a7d4": [
                                    {
                                        "on": "tap",
                                        "type": "action-type",
                                        "config": {
                                            "actionProp": true
                                        }
                                    }
                                ]
                            }
                        }
                    ]
                }
            ]
        }
        """#.data(using: .utf8)!

        // Act
        let experience = try? NetworkClient.decoder.decode(Experience.self, from: data)

        // Assert
        XCTAssertNotNil(experience)
    }

    func testDuplicateStepTraitDecode() throws {
        // Arrange
        let data = #"""
        {
            "id": "05e78601-d7d8-449f-a074-fe3ae1144366",
            "name": "duplicate step trait",
            "type": "mobile",
            "traits": [
                {
                    "type": "experience-trait"
                }
            ],
            "steps": [
                {
                    "id": "f7edb07c-5f96-4440-9b70-3bdd0b7675b0",
                    "type": "group",
                    "actions": {},
                    "traits": [
                        {
                            "type": "group-trait"
                        }
                    ],
                    "children": [
                        {
                            "id": "68bb5cc4-99b4-4f5c-a787-930ba921fc05",
                            "type": "modal",
                            "content": {
                                "type": "spacer",
                                "id": "1f9d1c11-525f-4f1c-afc1-d91b97c6a7d4"
                            },
                            "traits": [
                                {
                                    "type": "step-trait"
                                },
                                {
                                    "type": "step-trait"
                                }
                            ],
                            "actions": {}
                        }
                    ]
                }
            ]
        }
        """#.data(using: .utf8)!

        // Act
        var experience: Experience?
        var error: String?
        do {
            experience = try NetworkClient.decoder.decode(Experience.self, from: data)
        } catch let DecodingError.dataCorrupted(context) {
            error = "\(context)"
        }

        // Assert
        XCTAssertNil(experience)
        let unwrappedError = try XCTUnwrap(error)
        XCTAssertTrue(unwrappedError.contains("multiple traits of same type are not supported: step-trait"))
    }

    func testDuplicateGroupTraitDecode() throws {
        // Arrange
        let data = #"""
        {
            "id": "05e78601-d7d8-449f-a074-fe3ae1144366",
            "name": "duplicate step trait",
            "type": "mobile",
            "traits": [
                {
                    "type": "experience-trait"
                }
            ],
            "steps": [
                {
                    "id": "f7edb07c-5f96-4440-9b70-3bdd0b7675b0",
                    "type": "group",
                    "actions": {},
                    "traits": [
                        {
                            "type": "group-trait"
                        },
                        {
                            "type": "group-trait"
                        }
                    ],
                    "children": [
                        {
                            "id": "68bb5cc4-99b4-4f5c-a787-930ba921fc05",
                            "type": "modal",
                            "content": {
                                "type": "spacer",
                                "id": "1f9d1c11-525f-4f1c-afc1-d91b97c6a7d4"
                            },
                            "traits": [
                                {
                                    "type": "step-trait"
                                }
                            ],
                            "actions": {}
                        }
                    ]
                }
            ]
        }
        """#.data(using: .utf8)!

        // Act
        var experience: Experience?
        var error: String?
        do {
            experience = try NetworkClient.decoder.decode(Experience.self, from: data)
        } catch let DecodingError.dataCorrupted(context) {
            error = "\(context)"
        }

        // Assert
        XCTAssertNil(experience)
        let unwrappedError = try XCTUnwrap(error)
        XCTAssertTrue(unwrappedError.contains("multiple traits of same type are not supported: group-trait"))
    }

    func testDuplicateExperienceTraitDecode() throws {
        // Arrange
        let data = #"""
        {
            "id": "05e78601-d7d8-449f-a074-fe3ae1144366",
            "name": "duplicate experience trait",
            "type": "mobile",
            "traits": [
                {
                    "type": "experience-trait"
                },
                {
                    "type": "experience-trait"
                }
            ],
            "steps": [
                {
                    "id": "f7edb07c-5f96-4440-9b70-3bdd0b7675b0",
                    "type": "group",
                    "actions": {},
                    "traits": [
                        {
                            "type": "group-trait"
                        }
                    ],
                    "children": [
                        {
                            "id": "68bb5cc4-99b4-4f5c-a787-930ba921fc05",
                            "type": "modal",
                            "content": {
                                "type": "spacer",
                                "id": "1f9d1c11-525f-4f1c-afc1-d91b97c6a7d4"
                            },
                            "traits": [
                                {
                                    "type": "step-trait"
                                }
                            ],
                            "actions": {}
                        }
                    ]
                }
            ]
        }
        """#.data(using: .utf8)!

        // Act
        var experience: Experience?
        var error: String?
        do {
            experience = try NetworkClient.decoder.decode(Experience.self, from: data)
        } catch let DecodingError.dataCorrupted(context) {
            error = "\(context)"
        }

        // Assert
        XCTAssertNil(experience)
        let unwrappedError = try XCTUnwrap(error)
        XCTAssertTrue(unwrappedError.contains("multiple traits of same type are not supported: experience-trait"))
    }
}
