//
//  DynamicCodingKeys.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        // No int keys supported
        return nil
    }

    // Non-failable init for encoding
    init(key: String) {
        stringValue = key
    }
}

extension KeyedEncodingContainer where K == DynamicCodingKeys {

    /// Encodes the given dictionary to primitive types permitted by the Appcues API.
    ///
    /// An `EncodingError` will be thrown for non-permitted types, and that specific error should be caught and ignored by the caller of this func.
    mutating func encode(_ dict: [String: Any]?) throws {
        try dict?.forEach { key, value in
            let codingKey = DynamicCodingKeys(key: key)

            switch value {
            case let string as String:
                try self.encode(string, forKey: codingKey)
            case let bool as Bool:
                try self.encode(bool, forKey: codingKey)
            // swiftlint:disable:next legacy_objc_type
            case let number as NSNumber:
                try self.encode(number.decimalValue, forKey: codingKey)
            default:
                // Throw here instead of assertionFailure directly so we can test this case
                let context = EncodingError.Context(
                    codingPath: [codingKey],
                    debugDescription: "Only String, Number and Bool types allowed.",
                    underlyingError: AppcuesEncodingError.unsupportedType)
                throw EncodingError.invalidValue(value, context)
            }
        }
    }
}
