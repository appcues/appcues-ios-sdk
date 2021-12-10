//
//  KeyedDecodingContainer+PartialDictionaryDecode.swift
//  AppcuesKit
//
//  Created by Matt on 2021-12-10.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

extension KeyedDecodingContainer {

    /// Partially decode a JSON dictionary to primitive values, while leaving nested objects to be decoded to proper model types later on.
    ///
    /// Decodes `String`, `Bool`, `Int`, and `Double` to their primitive values.
    /// Anything else is mapped as a `KeyedDecodingContainer` and left to be decoded elsewhere where more type info may be known.
    ///
    /// **Example Usage**
    /// ```swift
    /// if let rawData = config?["key"] as? KeyedDecodingContainer<JSONCodingKeys>,
    ///    let key = JSONCodingKeys(stringValue: "key"),
    ///    let mappedModel = try? rawData.decode(MyModel.self, forKey: key) {
    ///     // do something with mappedModel
    /// }
    /// ```
    func partialDictionaryDecode(_ type: [String: Any].Type, forKey key: K) throws -> [String: Any] {
        let container = try self.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)
        return try container.partialDictionaryDecode(type)
    }

    func partialDictionaryDecode(_ type: [String: Any].Type) throws -> [String: Any] {
        var dictionary = [String: Any]()

        for key in allKeys {
            if let boolValue = try? decode(Bool.self, forKey: key) {
                dictionary[key.stringValue] = boolValue
            } else if let stringValue = try? decode(String.self, forKey: key) {
                dictionary[key.stringValue] = stringValue
            } else if let intValue = try? decode(Int.self, forKey: key) {
                dictionary[key.stringValue] = intValue
            } else if let doubleValue = try? decode(Double.self, forKey: key) {
                dictionary[key.stringValue] = doubleValue
            } else {
                dictionary[key.stringValue] = self
            }
        }
        return dictionary
    }
}

public extension Dictionary where Key == String, Value == Any {

    /// Designed for use in Appcues `ExperienceTrait` implementations where the `config` dictionary stores partially decoded containers.
    subscript<T: Decodable>(_ key: Key, decodedAs type: T.Type) -> T? {
        guard let container = self[key] as? KeyedDecodingContainer<JSONCodingKeys>,
              let key = JSONCodingKeys(stringValue: key) else { return nil }

        return try? container.decode(T.self, forKey: key)
    }
}
