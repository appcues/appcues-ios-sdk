//
//  Event.swift
//  Appcues
//
//  Created by Matt on 2021-10-07.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

/// API request structure for an activity event.
internal struct Event: Encodable {
    let name: String
    let timestamp: Date
    let attributes: [String: String]? // [String: Encodable]?

    init(name: String, timestamp: Date = Date(), attributes: [String: String]? = nil) {
        self.name = name
        self.timestamp = timestamp
        self.attributes = attributes
    }

    init(pageView url: String, attributes: [String: String]? = nil) {
        name = "appcues:page_view"
        timestamp = Date()

        var extendedAttributes = attributes ?? [:]
        extendedAttributes["url"] = url
        self.attributes = extendedAttributes
    }
}
