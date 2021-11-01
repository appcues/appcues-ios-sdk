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

    /// Encodes the given dictionary to primitive types permitted by the Appcues API, skipping invalid types.
    mutating func encodeSkippingInvalid(_ dict: [String: Any]?) throws {
        var encodingErrorKeys: [String] = []

        try dict?.forEach { key, value in
            let codingKey = DynamicCodingKeys(key: key)

            if key == "_identity", let autoprops = value as? Dictionary<String, Any> {
                // "_identity" is a special case - the Appcues auto-properties that supply app/user/session data
                var autopropContainer = self.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: codingKey)
                try autopropContainer.encodeSkippingInvalid(autoprops)
            } else {
                switch value {
                case let string as String:
                    try self.encode(string, forKey: codingKey)
                case let bool as Bool:
                    try self.encode(bool, forKey: codingKey)
                // swiftlint:disable:next legacy_objc_type
                case let number as NSNumber:
                    try self.encode(number.decimalValue, forKey: codingKey)
                default:
                    encodingErrorKeys.append(codingKey.stringValue)
                }
            }
        }

        if !encodingErrorKeys.isEmpty && ProcessInfo.processInfo.environment["XCTestBundlePath"] == nil {
            assertionFailure(
            """
            Unsupported value(s) included in \(self.codingPath) for key(s): \(encodingErrorKeys).
            Only String, Number, and Bool types allowed.
            """
            )
        }
    }
}
