//
//  DynamicCodingKeysTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2021-10-21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class DynamicCodingKeysTests: XCTestCase {

    var encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        if #available(iOS 11.0, *) {
            encoder.outputFormatting = .sortedKeys
        }
        return encoder
    }()

    func testEncodeDictAny() throws {
        // Arrange
        let testData = TestData(dict: ["string": "value", "int": 42, "double": 3.14, "number": NSNumber(1), "bool": true])

        // Act
        let data = try XCTUnwrap(encoder.encode(testData))

        // Assert
        let asString = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertEqual(asString, #"{"dict":{"bool":true,"double":3.14,"int":42,"number":1,"string":"value"}}"#)
    }

    func testEncodeDictAnyInvalid() throws {
        // Arrange
        let invalidValue = [1, 2, 3, 4]
        let testData = TestData(dict: ["before": 1, "invalid": invalidValue, "valid": "Valid value", "anotherInvalid": ["arr", "ay"]])

        // Act
        let data = try XCTUnwrap(try encoder.encode(testData))

        // Assert
        let asString = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertEqual(asString, #"{"dict":{"before":1,"valid":"Valid value"}}"#)
    }
}

extension DynamicCodingKeysTests {
    struct TestData: Encodable {
        let dict: [String: Any]

        enum CodingKeys: CodingKey {
            case dict
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            var dictContainer = container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .dict)
            try dictContainer.encodeSkippingInvalid(dict)
        }
    }
}
