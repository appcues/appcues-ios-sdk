//
//  AnalyticsBroadcasterTests.swift
//  AppcuesKit
//
//  Created by James Ellis on 6/27/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class AnalyticsBroadcasterTests: XCTestCase {

    var broadcaster: AnalyticsBroadcaster!
    var appcues: MockAppcues!
    var delegate: MockAnalyticsDelegate!

    override func setUpWithError() throws {
        let config = Appcues.Config(accountID: "00000", applicationID: "abc")

        appcues = MockAppcues(config: config)
        delegate = MockAnalyticsDelegate()
        broadcaster = AnalyticsBroadcaster(container: appcues.container)
        appcues.analyticsDelegate = delegate
    }

    func testBroadcastEvent() throws {
        // Act
        broadcaster.track(update: TrackingUpdate(type: .event(name: "my event", interactive: true), properties: ["key": "value"], context: nil, isInternal: true))

        // Assert
        XCTAssertEqual(delegate.lastAnalytic, .event)
        XCTAssertEqual(delegate.lastValue, "my event")
        ["key": "value"].verifyPropertiesMatch(delegate.lastProperties)
        XCTAssertEqual(delegate.lastIsInternal, true)
    }

    func testBroadcastScreen() throws {
        // Act
        broadcaster.track(update: TrackingUpdate(type: .screen("screen name"), properties: ["key": "value"], context: nil, isInternal: false))

        // Assert
        XCTAssertEqual(delegate.lastAnalytic, .screen)
        XCTAssertEqual(delegate.lastValue, "screen name")
        ["key": "value"].verifyPropertiesMatch(delegate.lastProperties)
        XCTAssertEqual(delegate.lastIsInternal, false)
    }

    func testBroadcastGroup() throws {
        // Act
        broadcaster.track(update: TrackingUpdate(type: .group("group name"), properties: ["key": "value"], context: nil, isInternal: false))

        // Assert
        XCTAssertEqual(delegate.lastAnalytic, .group)
        XCTAssertEqual(delegate.lastValue, "group name")
        ["key": "value"].verifyPropertiesMatch(delegate.lastProperties)
        XCTAssertEqual(delegate.lastIsInternal, false)
    }

    func testBroadcastProfile() throws {
        // Act
        broadcaster.track(update: TrackingUpdate(type: .profile, properties: ["key": "value"], context: nil, isInternal: false))

        // Assert
        XCTAssertEqual(delegate.lastAnalytic, .identify)
        XCTAssertEqual(delegate.lastValue, "user-id")
        ["key": "value"].verifyPropertiesMatch(delegate.lastProperties)
        XCTAssertEqual(delegate.lastIsInternal, false)
    }

    func testBroadcastSanitizesDates() throws {
        // Arrange
        let update = TrackingUpdate(
            type: .event(name: "some event", interactive: false),
            properties: [
                "someDate": Date(timeIntervalSince1970: 1665160001)
            ],
            isInternal: false)

        // Act
        broadcaster.track(update: update)

        // Assert
        XCTAssertEqual(delegate.lastAnalytic, .event)
        XCTAssertEqual(delegate.lastValue, "some event")
        [
            "someDate": 1665160001000
        ].verifyPropertiesMatch(delegate.lastProperties)
        XCTAssertEqual(delegate.lastIsInternal, false)
    }

    func testBroadcastSanitizesStepState() throws {
        // Arrange
        let expectedFormItem = ExperienceData.FormItem(model: ExperienceComponent.TextInputModel(
            id: UUID(uuidString: "85259845-9661-463d-a90a-f500ad7f7dcf")!,
            label: ExperienceComponent.TextModel(id: UUID(), text: "Form label", style: nil),
            errorLabel: nil,
            placeholder: nil,
            defaultValue: "default value",
            required: true,
            numberOfLines: nil,
            maxLength: nil,
            dataType: nil,
            textFieldStyle: nil,
            cursorColor: nil,
            style: nil))

        let update = TrackingUpdate(
            type: .event(name: "appcues:v2:step_interaction", interactive: false),
            properties: [
                "interactionType": "Form Submitted",
                "interactionData": [
                    "formResponse": ExperienceData.StepState(formItems: [
                        UUID(uuidString: "85259845-9661-463d-a90a-f500ad7f7dcf")!: expectedFormItem
                    ])
                ]
            ],
            isInternal: true)

        // Act
        broadcaster.track(update: update)

        // Assert
        XCTAssertEqual(delegate.lastAnalytic, .event)
        XCTAssertEqual(delegate.lastValue, "appcues:v2:step_interaction")
        [
            "interactionType": "Form Submitted",
            "interactionData": [
                "formResponse": [
                    [
                        "fieldId": "85259845-9661-463D-A90A-F500AD7F7DCF",
                        "fieldType": "textInput",
                        "fieldRequired": true,
                        "value": "default value",
                        "label": "Form label"
                    ]
                ]
            ]
        ].verifyPropertiesMatch(delegate.lastProperties)
        XCTAssertEqual(delegate.lastIsInternal, true)
    }
}

class MockAnalyticsDelegate: AppcuesAnalyticsDelegate {
    var lastAnalytic: AppcuesAnalytic?
    var lastValue: String?
    var lastProperties: [String: Any]?
    var lastIsInternal: Bool?

    func didTrack(analytic: AppcuesAnalytic, value: String?, properties: [String: Any]?, isInternal: Bool) {
        lastAnalytic = analytic
        lastValue = value
        lastProperties = properties
        lastIsInternal = isInternal
    }
}
