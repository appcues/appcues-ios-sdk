//
//  DecodingError+Custom.swift
//  AppcuesKit
//
//  Created by James Ellis on 12/2/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

extension DecodingError {
    var decodingErrorMessage: String? {
        switch self {
        case let DecodingError.dataCorrupted(context):
            return "\(context)"
        case let DecodingError.keyNotFound(key, context):
            return "key '\(key)' not found: \(context.debugDescription) codingPath: \(context.codingPath)"
        case let DecodingError.valueNotFound(value, context):
            return "value '\(value)' not found: \(context.debugDescription) codingPath: \(context.codingPath)"
        case let DecodingError.typeMismatch(type, context):
            return "type '\(type)' mismatch: \(context.debugDescription) codingPath: \(context.codingPath)"
        @unknown default:
            return "error: \(self)"
        }
    }
}
