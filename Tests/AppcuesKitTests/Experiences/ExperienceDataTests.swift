//
//  ExperienceDataTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-09-26.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

@available(iOS 13.0, *)
class ExperienceDataTests: XCTestCase {

    func testSingleSelectRequired() throws {
        // Arrange
        let model = ExperienceComponent.OptionSelectModel(
            selectMode: .single,
            optionCount: 5,
            minSelections: 1,
            maxSelections: nil)
        var formItem = ExperienceData.FormItem(model: model)

        // Act/Assert
        XCTAssertFalse(formItem.isSatisfied)
        formItem.setValue("2")
        XCTAssertTrue(formItem.isSatisfied)
        XCTAssertEqual(formItem.getValue(), "2")
        formItem.setValue("4")
        XCTAssertTrue(formItem.isSatisfied)
        XCTAssertEqual(formItem.getValue(), "4")
    }

    func testMultiSelectOrder() throws {
        // Arrange
        let model = ExperienceComponent.OptionSelectModel(
            selectMode: .multi,
            optionCount: 5,
            minSelections: nil,
            maxSelections: nil)
        var formItem = ExperienceData.FormItem(model: model)

        // Act/Assert
        XCTAssertTrue(formItem.isSatisfied)

        formItem.setValue("0")
        XCTAssertEqual(formItem.getValue(), "0")
        formItem.setValue("1")
        XCTAssertEqual(formItem.getValue(), "0,1")
        formItem.setValue("0")
        XCTAssertEqual(formItem.getValue(), "1")
        formItem.setValue("0")
        XCTAssertEqual(formItem.getValue(), "1,0")
    }

    func testMultiSelectMinSelections() throws {
        // Arrange
        let model = ExperienceComponent.OptionSelectModel(
            selectMode: .multi,
            optionCount: 5,
            minSelections: 1,
            maxSelections: nil)
        var formItem = ExperienceData.FormItem(model: model)

        // Act/Assert
        XCTAssertFalse(formItem.isSatisfied)
        formItem.setValue("0")
        XCTAssertTrue(formItem.isSatisfied)
        formItem.setValue("1")
        XCTAssertTrue(formItem.isSatisfied)
        formItem.setValue("1")
        XCTAssertTrue(formItem.isSatisfied)
        formItem.setValue("0")
        XCTAssertFalse(formItem.isSatisfied)
    }

    func testMultiSelectMaxSelections() throws {
        // Arrange
        let model = ExperienceComponent.OptionSelectModel(
            selectMode: .multi,
            optionCount: 5,
            minSelections: nil,
            maxSelections: 2)
        var formItem = ExperienceData.FormItem(model: model)

        // Act/Assert
        formItem.setValue("0")
        XCTAssertEqual(formItem.getValue(), "0")
        formItem.setValue("1")
        XCTAssertEqual(formItem.getValue(), "0,1")
        formItem.setValue("2")
        XCTAssertEqual(formItem.getValue(), "0,1", "exceeding max not set")
        formItem.setValue("1")
        XCTAssertEqual(formItem.getValue(), "0")
        formItem.setValue("2")
        XCTAssertEqual(formItem.getValue(), "0,2")
    }

    // We do no handling of the scenario where defaultValue.count > maxSelections.
    // The component will just initially be in an invalid state.
    // The user will be able to unselect items to get below maxSelections and then unable to select more items as usual.
    func testDefaultExceedsMax() throws {
        // Arrange
        let model = ExperienceComponent.OptionSelectModel(
            selectMode: .multi,
            optionCount: 5,
            minSelections: nil,
            maxSelections: 2,
            defaultValue: ["0", "1", "2"])
        var formItem = ExperienceData.FormItem(model: model)

        // Act/Assert
        XCTAssertFalse(formItem.isSatisfied)
        XCTAssertEqual(formItem.getValue(), "0,1,2")

        formItem.setValue("3")
        XCTAssertEqual(formItem.getValue(), "0,1,2", "exceeding max not set")

        formItem.setValue("2")
        formItem.setValue("1")
        formItem.setValue("3")
        XCTAssertEqual(formItem.getValue(), "0,3")
    }

    // If minSelections > options.count, minSelections will be set to options.count.
    func testMinSelectionsOverride() throws {
        // Arrange
        let model = ExperienceComponent.OptionSelectModel(
            selectMode: .multi,
            optionCount: 2,
            minSelections: 5,
            maxSelections: nil)
        var formItem = ExperienceData.FormItem(model: model)

        // Act/Assert
        formItem.setValue("0")
        XCTAssertFalse(formItem.isSatisfied)
        formItem.setValue("1")
        XCTAssertTrue(formItem.isSatisfied)
    }

    // If maxSelections < minSelections, maxSelections will be set to minSelections
    func testMaxSelectionsOverride() throws {
        // Arrange
        let model = ExperienceComponent.OptionSelectModel(
            selectMode: .multi,
            optionCount: 5,
            minSelections: 3,
            maxSelections: 2)
        var formItem = ExperienceData.FormItem(model: model)

        // Act/Assert
        formItem.setValue("0")
        formItem.setValue("1")
        formItem.setValue("2")
        XCTAssertEqual(formItem.getValue(), "0,1,2")

        formItem.setValue("3")
        XCTAssertEqual(formItem.getValue(), "0,1,2")
    }
}

extension ExperienceComponent.OptionSelectModel {
    init(selectMode: SelectMode, optionCount: Int, minSelections: UInt?, maxSelections: UInt?, defaultValue: [String]? = nil) {
        let options = (0..<optionCount).map {
            ExperienceComponent.FormOptionModel(
                value: "\($0)",
                content: .spacer(ExperienceComponent.SpacerModel(id: UUID(), spacing: nil, style: nil)),
                selectedContent: nil)
        }

        self.init(
            id: UUID(),
            label: ExperienceComponent.TextModel(id: UUID(), text: "Label", style: nil),
            selectMode: selectMode,
            options: options,
            defaultValue: defaultValue,
            minSelections: minSelections,
            maxSelections: maxSelections,
            controlPosition: .leading,
            displayFormat: .verticalList,
            selectedColor: nil,
            unselectedColor: nil,
            accentColor: nil,
            pickerStyle: nil,
            style: nil
        )
    }
}
