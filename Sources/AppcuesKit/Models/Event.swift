//
//  Event.swift
//  Appcues
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

    init(name: String, timestamp: Date = Date(), attributes: [String: Any]? = nil) {
        self.name = name
        self.timestamp = timestamp
        self.attributes = attributes
    }

    init(pageView url: String, attributes: [String: Any]? = nil) {
        name = "appcues:page_view"
        timestamp = Date()

        var extendedAttributes = attributes ?? [:]
        extendedAttributes["url"] = url
        self.attributes = extendedAttributes
    }
}

extension Event: Encodable {
    enum CodingKeys: CodingKey {
        case name
        case timestamp
        case attributes
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(timestamp, forKey: .timestamp)

        if let attributes = attributes {
            var attributesContainer = container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .attributes)
            try attributesContainer.encodeSkippingInvalid(attributes)
        }
    }
}
