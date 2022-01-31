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
        let actions: [String: [Action]]
    }

    struct Trait {
        let type: String
        let config: [String: Any]?
    }

    struct Action {
        let trigger: String
        let type: String
        let config: [String: Any]?
    }

    let id: UUID
    let name: String
    // tags, theme, actions
    // TODO: Handle experience-level actions
    let traits: [Trait]
    let steps: [Step]
}

extension Array where Element == Experience.Trait {
    var groupID: String? {
        self.first { $0.type == "@appcues/group-item" }?.config?["groupID"] as? String
    }
}

extension Experience.Trait: Decodable {
    private enum CodingKeys: CodingKey {
        case type
        case config
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        type = try container.decode(String.self, forKey: .type)
        config = (try? container.partialDictionaryDecode([String: Any].self, forKey: .config)) ?? [:]
    }
}

extension Experience.Action: Decodable {
    private enum CodingKeys: String, CodingKey {
        case trigger = "on"
        case type
        case config
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        trigger = try container.decode(String.self, forKey: .trigger)
        type = try container.decode(String.self, forKey: .type)
        config = (try? container.decode([String: Any].self, forKey: .config)) ?? [:]
    }

}
