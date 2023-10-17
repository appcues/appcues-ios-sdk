//
//  LoggedEventTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2023-10-16.
//  Copyright © 2023 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

@available(iOS 13.0, *)
class LoggedEventTests: XCTestCase {

    func testPropertyGrouping() throws {
        let autoPropertyDecorator = AutoPropertyDecorator(container: MockAppcues().container)
        let formResponse = ExperienceData.StepState(formItems: [
            UUID(): ExperienceData.FormItem(model: ExperienceComponent.TextInputModel(
                id: UUID(),
                label: ExperienceComponent.TextModel(id: UUID(), text: "label"),
                errorLabel: nil,
                placeholder: nil,
                defaultValue: "value",
                required: nil,
                numberOfLines: nil,
                maxLength: nil,
                dataType: nil,
                textFieldStyle: nil,
                cursorColor: nil,
                attributeName: nil,
                style: nil
            ))
        ])
        let rawUpdate = TrackingUpdate(
            type: .event(name: "My Event", interactive: true),
            properties: [
                // Note that not all these properties will exist on the same event, but we can still test them all at once.
                "my-prop": true,
                "_sdkMetrics": [
                    "timeBeforeRequest": 100
                ],
                "_identity": [
                    "my-prop": true,
                ],
                "interactionData": [
                    "category": "internal",
                    "formResponse": formResponse
                ] as [String : Any]
            ],
            isInternal: false)
        let decoratedUpdate = autoPropertyDecorator.decorate(rawUpdate)

        // Act
        let event = LoggedEvent(from: decoratedUpdate)

        // Assert
        let groupedProperties = try XCTUnwrap(event.eventProperties)
        XCTAssertEqual(groupedProperties.count, 5)
        XCTAssertEqual(groupedProperties[safe: 0]?.title, "Properties")
        XCTAssertEqual(groupedProperties[safe: 1]?.title, "Interaction Data")
        XCTAssertEqual(groupedProperties[safe: 2]?.title, "Interaction Data: Form Response")
        XCTAssertEqual(groupedProperties[safe: 3]?.title, "Identity Auto-properties")
        XCTAssertEqual(groupedProperties[safe: 4]?.title, "SDK Metrics")

        XCTAssertEqual(event.eventDetailItems.count, 3)
        XCTAssertEqual(event.eventDetailItems[safe: 0]?.title, "Type")
        XCTAssertEqual(event.eventDetailItems[safe: 1]?.title, "Name")
        XCTAssertEqual(event.eventDetailItems[safe: 2]?.title, "Timestamp")
    }

    func testNoAutoProperties() throws {
        let update = TrackingUpdate(type: .event(name: "My Event", interactive: true), properties: ["my-prop": true], isInternal: false)

        // Act
        let event = LoggedEvent(from: update)

        // Assert
        let groupedProperties = try XCTUnwrap(event.eventProperties)
        XCTAssertEqual(groupedProperties.count, 1)
        XCTAssertEqual(groupedProperties[safe: 0]?.title, "Properties")
    }

    func testNoProperties() throws {
        let update = TrackingUpdate(type: .event(name: "My Event", interactive: true), isInternal: false)

        // Act
        let event = LoggedEvent(from: update)

        // Assert
        XCTAssertNil(event.eventProperties)
    }

}
