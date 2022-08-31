//
//  ElementSelector.swift
//  AppcuesKit
//
//  Created by Matt on 2022-08-31.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

internal enum ElementSelector: Codable, Equatable {
    case tag(Int)
    case accessibilityID(String)
    case unknown

    init?(_ value: String?) {
        guard let value = value else { return nil }

        switch value.first {
        case "@":
            guard let tag = Int(value.dropFirst()) else { return nil }
            self = .tag(tag)
        case "#":
            self = .accessibilityID(String(value.dropFirst()))
        case "*":
            self = .unknown
        default:
            return nil
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)

        switch value.first {
        case "@":
            guard let tag = Int(value.dropFirst()) else {
                throw DecodingError.typeMismatch(
                    Int.self,
                    DecodingError.Context(
                        codingPath: container.codingPath,
                        debugDescription: "Tag selector not a number"))
            }
            self = .tag(tag)
        case "#":
            self = .accessibilityID(String(value.dropFirst()))
        case "*":
            fallthrough
        default:
            self = .unknown
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .tag(let tag):
            try container.encode("@\(tag)")
        case .accessibilityID(let accessibilityID):
            try container.encode("#\(accessibilityID)")
        case .unknown:
            try container.encode("*")
        }
    }

}
