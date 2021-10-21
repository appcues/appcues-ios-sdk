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
        encoder.outputFormatting = .sortedKeys
        return encoder
    }()

    func testEncodeDictAny() throws {
        // Arrange
        let testData = TestData(dict: ["string": "value", "int": 42, "double": 3.14, "bool": true])

        // Act
        let data = try XCTUnwrap(encoder.encode(testData))

        // Assert
        let asString = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertEqual(asString, #"{"dict":{"bool":true,"double":3.1400000000000001,"int":42,"string":"value"}}"#)
    }

    func testEncodeDictAnyFailure() throws {
        // Arrange
        let invalidValue = Date()
        let testData = TestData(dict: ["invalid": invalidValue])

        // Act/Assert
        XCTAssertThrowsError(try encoder.encode(testData)) { error in
            switch error as? EncodingError {
            case let .invalidValue(value, context):
                XCTAssertEqual(value as? Date, invalidValue)
                XCTAssertEqual(context.debugDescription, "Only String, Number and Bool types allowed.")
            default:
                XCTFail("Unexpected encoder error.")
            }
        }
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
            try dictContainer.encode(dict)
        }

    }
}
