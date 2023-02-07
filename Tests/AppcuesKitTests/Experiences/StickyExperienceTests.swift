//
//  StickyExperienceTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2023-02-07.
//  Copyright © 2023 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class StickyExperienceTests: XCTestCase {
    func testInit() throws {
        let experienceStepString = """
        {
            "id": "5f1522d9-8fb4-4e0f-aa70-bda35941614d",
            "type": "modal",
            "contentType": "application/json",
            "content": {
                "type": "stack",
                "orientation": "vertical",
                "id": "3be3db4f-9e07-4dab-9067-6df6b8c41f0a",
                "style": {},
                "items": [
                    {
                        "type": "stack",
                        "id": "25c76b20-fbf4-4d8c-b2ce-e5e776a0b666",
                        "orientation": "horizontal",
                        "distribution": "equal",
                        "sticky": "top",
                        "items": [
                            {
                                "type": "text",
                                "id": "86d0fc1d-003b-4246-ac4e-37e8ff313a04",
                                "text": "Sticky Top",
                                "style": {}
                            }
                        ]
                    },
                    {
                        "type": "stack",
                        "id": "c1f894cf-7233-4e33-895c-3bae6632bcb0",
                        "orientation": "horizontal",
                        "distribution": "equal",
                        "items": [
                            {
                                "type": "text",
                                "id": "a4769319-795e-4989-bb1e-a4491c021415",
                                "text": "Non Sticky",
                                "style": {}
                            }
                        ]
                    },
                    {
                        "type": "stack",
                        "id": "e120fc7d-b4e2-4e34-9052-e05731a61773",
                        "orientation": "horizontal",
                        "distribution": "equal",
                        "sticky": "bottom",
                        "items": [
                            {
                                "type": "text",
                                "id": "c7a847ba-7527-4b7d-afa5-c7794016e67b",
                                "text": "Sticky Bottom 1",
                                "style": {}
                            }
                        ]
                    },
                    {
                        "type": "stack",
                        "id": "bd77378d-c66b-4f08-a01d-30047205bcb7",
                        "orientation": "horizontal",
                        "distribution": "equal",
                        "sticky": "bottom",
                        "items": [
                            {
                                "type": "text",
                                "id": "8a987ea3-1fe3-4545-a96f-3114aeef571e",
                                "text": "Sticky Bottom 2",
                                "style": {}
                            }
                        ]
                    }
                ]
            },
            "traits": [],
            "actions": {}
        }
        """
        let experienceStepData = try XCTUnwrap(experienceStepString.data(using: .utf8))

        let step = try XCTUnwrap(try JSONDecoder().decode(Experience.Step.Child.self, from: experienceStepData))

        XCTAssertNotNil(step.stickyTopContent)
        XCTAssertEqual(
            step.stickyTopContent?.id,
            UUID(uuidString: "25c76b20-fbf4-4d8c-b2ce-e5e776a0b666"),
            "top content ID matches model because there's only a single item")
        XCTAssertNotNil(step.stickyBottomContent)

        if case let .stack(stackModel) = step.content {
            XCTAssertEqual(stackModel.items.count, 1, "only 1 non-sticky item remains in the body")
        } else {
            XCTFail("unexpected body structure")
        }
    }
}
