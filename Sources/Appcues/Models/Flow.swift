//
//  Flow.swift
//  Appcues
//
//  Created by Matt on 2021-10-08.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal struct Flow {
    enum State: String, Decodable {
        // TODO: What are the other possible states?
        case published = "PUBLISHED"
    }

    let id: String
    let name: String
    let createdAt: Date
    let updatedAt: Date
    let context: [String: Any]

    let state: State
    let steps: [String: Any]
}

extension Flow: Decodable {
    enum CodingKeys: CodingKey {
        case id
        case name
        case createdAt
        case updatedAt
        case context
        case attributes
    }

    enum AttributeKeys: CodingKey {
        case state
        case steps
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        context = try container.decode([String: Any].self, forKey: .context)

        let attributesContainer = try container.nestedContainer(keyedBy: AttributeKeys.self, forKey: .attributes)
        state = try attributesContainer.decode(State.self, forKey: .state)
        steps = try attributesContainer.decode([String: Any].self, forKey: .steps)
    }
}
