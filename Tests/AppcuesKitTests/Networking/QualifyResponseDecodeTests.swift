//
//  QualifyResponseDecodeTests.swift
//  AppcuesKitTests
//
//  Created by James Ellis on 12/2/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

import XCTest
@testable import AppcuesKit

class QualifyResponseDecodeTests: XCTestCase {

    // test lossy decoding of the experiences array returned from qualification
    func testLossyExperienceDecode() throws {
        // Arrange
        let data = #"""
        {
            "checklists": [],
            "contents": [],
            "experiences": [
                {
                    "id": "7bba162e-9846-449c-98c7-6891adc882ea",
                    "name": "missing type on content block",
                    "type": "mobile",
                    "traits": [],
                    "steps": [
                        {
                            "id": "19bc7372-ce17-437e-83b6-45ec9999c8cf",
                            "type": "group",
                            "actions": {},
                            "traits": [],
                            "children": [
                                {
                                    "id": "d4d44dc3-160b-42df-b0f8-ac3bc178e12a",
                                    "type": "modal",
                                    "content": {
                                        "id": "e61d6b61-ef92-46c4-9450-9c043cc80e39"
                                    },
                                    "traits": [],
                                    "actions": {}
                                }
                            ]
                        }
                    ]
                },
                {
                    "id": "05e78601-d7d8-449f-a074-fe3ae1144366",
                    "name": "valid 1",
                    "type": "mobile",
                    "traits": [],
                    "steps": [
                        {
                            "id": "f7edb07c-5f96-4440-9b70-3bdd0b7675b0",
                            "type": "group",
                            "actions": {},
                            "traits": [],
                            "children": [
                                {
                                    "id": "68bb5cc4-99b4-4f5c-a787-930ba921fc05",
                                    "type": "modal",
                                    "content": {
                                        "type": "spacer",
                                        "id": "1f9d1c11-525f-4f1c-afc1-d91b97c6a7d4"
                                    },
                                    "traits": [],
                                    "actions": {}
                                }
                            ]
                        }
                    ]
                },
                {
                    "unknown": true
                },
                {
                    "id": "c77a4ba2-2259-47b6-b380-76dac48f1c25",
                    "name": "valid 2",
                    "type": "mobile",
                    "traits": [],
                    "steps": [
                        {
                            "id": "fdfbc590-a00f-4319-aeb5-af23460b0f71",
                            "type": "group",
                            "actions": {},
                            "traits": [],
                            "children": [
                                {
                                    "id": "e793d69b-c89f-40a1-80b0-9146adb4ada8",
                                    "type": "modal",
                                    "content": {
                                        "type": "spacer",
                                        "id": "e2306fdd-0f95-4dc5-b5b1-75582cf79a84"
                                    },
                                    "traits": [],
                                    "actions": {}
                                }
                            ]
                        }
                    ]
                },
                {
                    "unknown": true
                },
                {
                    "id": "6f0db437-1d1e-4d74-af4d-9cb1257b5d46",
                    "name": "missing step traits",
                    "type": "mobile",
                    "traits": [],
                    "steps": [
                        {
                            "id": "7dce0c8c-590e-43bc-9856-4baa77566ac1",
                            "type": "group",
                            "actions": {},
                            "traits": [],
                            "children": [
                                {
                                    "id": "4e3d103b-0bbb-4449-8766-d0006a1d22e1",
                                    "type": null,
                                    "content": {
                                        "type": "spacer",
                                        "id": "856fd2f6-cb18-4ade-b834-4b0fcef27915"
                                    },
                                    "actions": {},
                                }
                            ]
                        }
                    ]
                },
                {
                    "id": "092faf58-f52d-457d-88c5-172d128d2c25",
                    "name": "valid 3",
                    "type": "mobile",
                    "traits": [],
                    "steps": [
                        {
                            "id": "56629029-9478-4db3-90fa-d8bcdf247ed4",
                            "type": "group",
                            "actions": {},
                            "traits": [],
                            "children": [
                                {
                                    "id": "047ca98a-0511-4030-b028-765f4344e5d1",
                                    "type": "modal",
                                    "content": {
                                        "type": "spacer",
                                        "id": "70a54b3c-7a4d-449a-8d0c-91a0203eafba"
                                    },
                                    "traits": [],
                                    "actions": {}
                                }
                            ]
                        }
                    ]
                },
                {
                    "id": "c9c11671-f418-451e-9b4a-33d54ed5299f",
                    "name": "step type wrong type",
                    "type": "mobile",
                    "traits": [],
                    "steps": [
                        {
                            "id": "4e82600a-fe5e-4072-8dd8-3833d8780b7e",
                            "type": 12,
                            "actions": {},
                            "traits": [],
                            "children": [
                                {
                                    "id": "ffe47297-4855-436d-87fa-e521ed211f32",
                                    "type": "modal",
                                    "content": {
                                        "type": "spacer",
                                        "id": "05fb351d-088c-4cc0-ae1e-7a13dcf2edf5"
                                    },
                                    "traits": [],
                                    "actions": {}
                                }
                            ]
                        }
                    ]
                }
            ],
            "performed_qualification": true,
            "profile": {
                "_ABGroup": 1
            },
            "qualification_reason": "screen_view",
            "request_id": "814EF333-6C88-4354-985B-9B5FE930F8DB"
        }
        """#.data(using: .utf8)!

        // Act
        let qualifyResponse = try NetworkClient.decoder.decode(QualifyResponse.self, from: data)

        // Assert

        // this example has 8 experiences
        // 0. invalid experience missing the type on the content block
        // 1. a valid experience
        // 2. unknown json object
        // 3. a valid experience
        // 4. unknown json object
        // 5. invalid experience - step type null
        // 6. a valid experience
        // 7. invalid experience - step type wrong data type (number instead of string)
        //
        // this should result in 6 items actually getting deserialized
        // 3 valid items - 1, 3 and 6
        // 3 invalid items but with enough to report error - 0, 5 and 7
        XCTAssertEqual(6, qualifyResponse.experiences.count)
        guard case let .failed(item0) = qualifyResponse.experiences[0] else { return XCTFail() }
        guard case let .decoded(item1) = qualifyResponse.experiences[1] else { return XCTFail() }
        guard case let .decoded(item3) = qualifyResponse.experiences[2] else { return XCTFail() }
        guard case let .failed(item5) = qualifyResponse.experiences[3] else { return XCTFail() }
        guard case let .decoded(item6) = qualifyResponse.experiences[4] else { return XCTFail() }
        guard case let .failed(item7) = qualifyResponse.experiences[5] else { return XCTFail() }

        XCTAssertEqual("7bba162e-9846-449c-98c7-6891adc882ea", item0.id.appcuesFormatted)
        XCTAssertEqual("05e78601-d7d8-449f-a074-fe3ae1144366", item1.id.appcuesFormatted)
        XCTAssertEqual("c77a4ba2-2259-47b6-b380-76dac48f1c25", item3.id.appcuesFormatted)
        XCTAssertEqual("6f0db437-1d1e-4d74-af4d-9cb1257b5d46", item5.id.appcuesFormatted)
        XCTAssertEqual("092faf58-f52d-457d-88c5-172d128d2c25", item6.id.appcuesFormatted)
        XCTAssertEqual("c9c11671-f418-451e-9b4a-33d54ed5299f", item7.id.appcuesFormatted)


        XCTAssertTrue(item0.error!.starts(with: "key 'CodingKeys(stringValue: \"type\", intValue: nil)' not found"))
        XCTAssertTrue(item5.error!.starts(with: "value 'String' not found: Expected String value but found null instead"))
        XCTAssertTrue(item7.error!.starts(with: "type 'String' mismatch: Expected to decode String but found a number instead"))
    }
}
