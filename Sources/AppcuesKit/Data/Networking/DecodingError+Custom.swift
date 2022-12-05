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
        let message: String
        switch self {
        case let DecodingError.dataCorrupted(context):
            message = "\(context)"
        case let DecodingError.keyNotFound(key, context):
            message = "key '\(key)' not found: \(context.debugDescription) codingPath: \(context.codingPath)"
        case let DecodingError.valueNotFound(value, context):
            message = "value '\(value)' not found: \(context.debugDescription) codingPath: \(context.codingPath)"
        case let DecodingError.typeMismatch(type, context):
            message = "type '\(type)' mismatch: \(context.debugDescription) codingPath: \(context.codingPath)"
        @unknown default:
            message = "error: \(self)"
        }

        return "Error parsing Experience JSON data: \(message)"
    }
}
