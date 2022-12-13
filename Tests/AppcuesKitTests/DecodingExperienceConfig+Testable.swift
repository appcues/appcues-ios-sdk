//
//  DecodingExperienceConfig+Testable.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-12-12.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation
import XCTest
@testable import AppcuesKit

// Allows initializing a DecodingExperienceConfig from a test with a plain dictionary
extension DecodingExperienceConfig {
    convenience init(_ testDict: [String: Any]?) {
        self.init(testDict?.toDecodableDict())
    }
}

extension Dictionary where Key == String, Value == Any {

    // Convert an arbitrary dictionary to a format that matches what `DecodingExperienceConfig` expects
    func toDecodableDict() -> [String: KeyedDecodingContainer<JSONCodingKeys>] {
        self.reduce(into: [:]) { dict, pair in
            if let expectation = pair.value as? XCTestExpectation {
                // special case
                dict[pair.key] = KeyedDecodingContainer(FakeDecodingContainer(DecodableExpectation(expectation: expectation)))
            } else {
                dict[pair.key] = KeyedDecodingContainer(FakeDecodingContainer(pair.value))
            }
        }
    }
}


// XCTestExpectation isn't Decodable, so fake it with this wrapper that stores the expectation in a static var to "decode" from
struct DecodableExpectation: Decodable {
    private static var expectationStore: [UUID: XCTestExpectation] = [:]

    let expectation: XCTestExpectation
    private let expectationID: UUID

    init(expectation: XCTestExpectation) {
        self.expectation = expectation
        self.expectationID = UUID()
        Self.expectationStore[expectationID] = expectation
    }

    enum CodingKeys: CodingKey {
        case expectationID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.expectationID = try container.decode(UUID.self, forKey: .expectationID)
        if let expectation = Self.expectationStore[expectationID] {
            self.expectation = expectation
        } else {
            throw DecodingError.valueNotFound(XCTestExpectation.self, .init(codingPath: [], debugDescription: "cant find expectation"))
        }
    }
}

// A "fake" Decoder that stores and returns values from test configs. Most methods are unimplemented since they're unused in tests,
// but they can be implemented if needed.
private struct FakeDecodingContainer: KeyedDecodingContainerProtocol {
    typealias Key = JSONCodingKeys

    let value: Any

    var codingPath: [CodingKey] = []
    var allKeys: [JSONCodingKeys] = []

    init(_ value: Any) {
        self.value = value
    }

    func contains(_ key: JSONCodingKeys) -> Bool {
        fatalError("unimplemented")
    }

    func decodeNil(forKey key: JSONCodingKeys) throws -> Bool {
        fatalError("unimplemented")
    }

    func decode(_ type: Bool.Type, forKey key: JSONCodingKeys) throws -> Bool {
        guard let castValue = value as? Bool else {
            throw DecodingError.typeMismatch(type, .init(codingPath: codingPath, debugDescription: "uh oh"))
        }
        return castValue
    }

    func decode(_ type: String.Type, forKey key: JSONCodingKeys) throws -> String {
        guard let castValue = value as? String else {
            throw DecodingError.typeMismatch(type, .init(codingPath: codingPath, debugDescription: "uh oh"))
        }
        return castValue
    }

    func decode(_ type: Double.Type, forKey key: JSONCodingKeys) throws -> Double {
        fatalError("unimplemented")
    }

    func decode(_ type: Float.Type, forKey key: JSONCodingKeys) throws -> Float {
        fatalError("unimplemented")
    }

    func decode(_ type: Int.Type, forKey key: JSONCodingKeys) throws -> Int {
        guard let castValue = value as? Int else {
            throw DecodingError.typeMismatch(type, .init(codingPath: codingPath, debugDescription: "uh oh"))
        }
        return castValue
    }

    func decode(_ type: Int8.Type, forKey key: JSONCodingKeys) throws -> Int8 {
        fatalError("unimplemented")
    }

    func decode(_ type: Int16.Type, forKey key: JSONCodingKeys) throws -> Int16 {
        fatalError("unimplemented")
    }

    func decode(_ type: Int32.Type, forKey key: JSONCodingKeys) throws -> Int32 {
        fatalError("unimplemented")
    }

    func decode(_ type: Int64.Type, forKey key: JSONCodingKeys) throws -> Int64 {
        fatalError("unimplemented")
    }

    func decode(_ type: UInt.Type, forKey key: JSONCodingKeys) throws -> UInt {
        fatalError("unimplemented")
    }

    func decode(_ type: UInt8.Type, forKey key: JSONCodingKeys) throws -> UInt8 {
        fatalError("unimplemented")
    }

    func decode(_ type: UInt16.Type, forKey key: JSONCodingKeys) throws -> UInt16 {
        fatalError("unimplemented")
    }

    func decode(_ type: UInt32.Type, forKey key: JSONCodingKeys) throws -> UInt32 {
        fatalError("unimplemented")
    }

    func decode(_ type: UInt64.Type, forKey key: JSONCodingKeys) throws -> UInt64 {
        fatalError("unimplemented")
    }

    func decode<T>(_ type: T.Type, forKey key: JSONCodingKeys) throws -> T where T : Decodable {
        guard let castValue = value as? T else {
            fatalError("uh oh \(type): \(value)")
        }
        return castValue
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: JSONCodingKeys) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        fatalError("unimplemented")
    }

    func nestedUnkeyedContainer(forKey key: JSONCodingKeys) throws -> UnkeyedDecodingContainer {
        fatalError("unimplemented")
    }

    func superDecoder() throws -> Decoder {
        fatalError("unimplemented")
    }

    func superDecoder(forKey key: JSONCodingKeys) throws -> Decoder {
        fatalError("unimplemented")
    }
}
