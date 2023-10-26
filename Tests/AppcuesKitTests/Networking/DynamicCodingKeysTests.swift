//
//  DynamicCodingKeysTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2021-10-21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

@available(iOS 13.0, *)
class DynamicCodingKeysTests: XCTestCase {

    var encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
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
        XCTAssertEqual(testData.logger.log.count, 0)
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
        XCTAssertEqual(testData.logger.log.count, 1)
        let log = try XCTUnwrap(testData.logger.log.first)
        XCTAssertEqual(log.level, .error)
        XCTAssertEqual(log.message, #"Unsupported value(s) included in dict when encoding key(s): ["anotherInvalid", "invalid"].\#nThese keys have been omitted. Only String, Number, Date, URL and Bool types allowed."#)
    }
}

@available(iOS 13.0, *)
extension DynamicCodingKeysTests {
    struct TestData: Encodable {
        let logger = DebugLogger(previousLogger: nil)

        let dict: [String: Any]

        enum CodingKeys: CodingKey {
            case dict
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            var dictContainer = container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .dict)
            try dictContainer.encodeSkippingInvalid(dict, logger: logger)
        }
    }
}
