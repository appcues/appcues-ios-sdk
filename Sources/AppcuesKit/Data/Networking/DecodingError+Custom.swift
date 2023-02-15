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
            message = "Expected key '\(key.pretty)' not found at codingPath: \(context.codingPath.pretty)"
        case let DecodingError.valueNotFound(_, context):
            message = "\(context.debugDescription) codingPath: \(context.codingPath.pretty)"
        case let DecodingError.typeMismatch(_, context):
            message = "\(context.debugDescription) codingPath: \(context.codingPath.pretty)"
        @unknown default:
            message = "error: \(self)"
        }

        return "Error parsing Experience JSON data: \(message)"
    }
}

extension CodingKey {
    var pretty: String {
        if let intValue = intValue {
            return "\(intValue)"
        }

        return stringValue
    }
}

extension Array where Element == CodingKey {
    var pretty: String {
        String(self
            .map { $0.pretty }
            .joined(separator: "."))
    }
}
