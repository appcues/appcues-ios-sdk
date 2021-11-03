//
//  Experience.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal struct Experience: Decodable {

    struct Step: Decodable {
        let id: UUID
        let contentType: String
        let content: ExperienceComponent
        let traits: [Trait]
    }

    struct Trait {
        let type: String
        let config: [String: Any]?
    }

    let id: UUID
    let name: String
    // tags, theme, actions, traits
    // TODO: Handle experience traits
    let steps: [Step]
}

extension Experience.Trait: Decodable {
    private enum CodingKeys: CodingKey {
        case type
        case config
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        type = try container.decode(String.self, forKey: .type)
        config = (try? container.decode([String: Any].self, forKey: .config)) ?? [:]
    }
}
