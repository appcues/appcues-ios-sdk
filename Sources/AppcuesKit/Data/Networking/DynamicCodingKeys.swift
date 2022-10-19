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

        // swiftlint:disable:next closure_body_length
        try dict?.forEach { key, value in
            let codingKey = DynamicCodingKeys(key: key)

            if (key == "_identity" || key == "interactionData" || key == "_sdkMetrics"), let nestedProps = value as? [String: Any] {
                // "_identity" is a special case - the Appcues auto-properties that supply app/user/session data
                // "interactionData" is a special case where a nested object is expected
                // "_sdkMetrics" is a special case - the Experience rendering timing metrics
                var autopropContainer = self.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: codingKey)
                try autopropContainer.encodeSkippingInvalid(nestedProps)
            } else if #available(iOS 13.0, *), let stepState = value as? ExperienceData.StepState {
                // Allow encoding the nested StepState structure since platform expects it
                try self.encode(stepState, forKey: codingKey)
            } else {
                switch value {
                case let string as String:
                    try self.encode(string, forKey: codingKey)
                case let url as URL:
                    try self.encode(url.absoluteString, forKey: codingKey)
                // swiftlint:disable:next legacy_objc_type
                case let number as NSNumber:
                    if isBoolNumber(number), let bool = number as? Bool {
                        try self.encode(bool, forKey: codingKey)
                    } else {
                        try self.encode(number.decimalValue, forKey: codingKey)
                    }
                case let bool as Bool:
                    try self.encode(bool, forKey: codingKey)
                case let date as Date:
                    try self.encode(date, forKey: codingKey)
                default:
                    encodingErrorKeys.append(codingKey.stringValue)
                }
            }
        }

        if !encodingErrorKeys.isEmpty && ProcessInfo.processInfo.environment["XCTestBundlePath"] == nil {
            assertionFailure(
            """
            Unsupported value(s) included in \(self.codingPath) for key(s): \(encodingErrorKeys).
            Only String, Number, Date, URL and Bool types allowed.
            """
            )
        }
    }

    // helper to determine if an NSNumber is actually containing a Boolean value
    // swiftlint:disable:next legacy_objc_type
    private func isBoolNumber(_ num: NSNumber) -> Bool {
        let boolID = CFBooleanGetTypeID() // the type ID of CFBoolean
        let numID = CFGetTypeID(num) // the type ID of num
        return numID == boolID
    }
}
