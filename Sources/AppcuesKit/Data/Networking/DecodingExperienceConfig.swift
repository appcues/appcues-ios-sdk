//
//  DecodingExperienceConfig.swift
//  AppcuesKit
//
//  Created by Matt on 2022-12-12.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

/// Object that stores the configuration options provided in ``Experience.Trait`` and ``Experience.Action`` models.
public class DecodingExperienceConfig: NSObject {
    // this is a class only for @objc compatibility

    private let properties: [String: KeyedDecodingContainer<JSONCodingKeys>]

    init(_ properties: [String: KeyedDecodingContainer<JSONCodingKeys>]?) {
        self.properties = properties ?? [:]
    }

    /// Accesses the value associated with the given key for reading.
    ///
    /// The value will be decoded from the configuration to the expected type.
    public subscript<T: Decodable>(_ key: String) -> T? {
        guard let container = properties[key], let key = JSONCodingKeys(stringValue: key) else { return nil }

        return try? container.decode(T.self, forKey: key)
    }
}

extension DecodingExperienceConfig {
    // Map the properties for the @appcues/update-profile action
    var safeValues: [String: Any] {
        properties.reduce(into: [:]) { dict, pair in
            guard let key = JSONCodingKeys(stringValue: pair.key) else { return }
            let container = pair.value

            if let boolValue = try? container.decode(Bool.self, forKey: key) {
                dict[key.stringValue] = boolValue
            } else if let stringValue = try? container.decode(String.self, forKey: key) {
                dict[key.stringValue] = stringValue
            } else if let intValue = try? container.decode(Int.self, forKey: key) {
                dict[key.stringValue] = intValue
            } else if let doubleValue = try? container.decode(Double.self, forKey: key) {
                dict[key.stringValue] = doubleValue
            } else {
                // not a supported type
            }
        }
    }
}
