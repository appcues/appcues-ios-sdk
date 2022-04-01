//
//  Event.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-07.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

/// API request structure for an activity event.
internal struct Event {
    let name: String
    let timestamp: Date
    let attributes: [String: Any]?
    let context: [String: Any]?

    init(name: String, timestamp: Date = Date(), attributes: [String: Any]? = nil, context: [String: Any]? = nil) {
        self.name = name
        self.timestamp = timestamp
        self.attributes = attributes
        self.context = context
    }

    init(screen screenTitle: String, attributes: [String: Any]? = nil, context: [String: Any]? = nil) {
        name = "appcues:screen_view"
        timestamp = Date()

        var extendedAttributes = attributes ?? [:]
        extendedAttributes["screenTitle"] = screenTitle
        self.attributes = extendedAttributes
        self.context = context
    }
}

extension Event: Encodable {
    enum CodingKeys: CodingKey {
        case name
        case timestamp
        case attributes
        case context
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(timestamp, forKey: .timestamp)

        if let attributes = attributes {
            var attributesContainer = container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .attributes)
            try attributesContainer.encodeSkippingInvalid(attributes)
        }

        if let context = context {
            var attributesContainer = container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .context)
            try attributesContainer.encodeSkippingInvalid(context)
        }
    }
}
