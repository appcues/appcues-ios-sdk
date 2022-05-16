//
//  Experience.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal protocol StepModel {
    var id: UUID { get }
    var type: String { get }
    var traits: [Experience.Trait] { get }
    var actions: [String: [Experience.Action]] { get }
}

internal struct Experience {

    @dynamicMemberLookup
    enum Step {
        case group(Group)
        case child(Child)

        var items: [Child] {
            switch self {
            case .group(let stepGroup):
                return stepGroup.children
            case .child(let stepChild):
                return [stepChild]
            }
        }

        subscript<T>(dynamicMember keyPath: KeyPath<StepModel, T>) -> T {
            switch self {
            case .group(let group): return group[keyPath: keyPath]
            case .child(let child): return child[keyPath: keyPath]
            }
        }
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
    let type: String
    // a millisecond timestamp
    let publishedAt: Int?
    // tags, theme, actions
    // TODO: Handle experience-level actions
    let traits: [Trait]
    let steps: [Step]

    /// Unique ID to disambiguate the same experience flowing through the system from different origins.
    let instanceID = UUID()
}

extension Experience: Decodable {
    private enum CodingKeys: CodingKey {
        case id, name, type, publishedAt, traits, steps
    }
}

extension Experience.Step: Decodable {
    struct Group: StepModel, Decodable {
        let id: UUID
        let type: String
        let children: [Child]
        let traits: [Experience.Trait]
        let actions: [String: [Experience.Action]]
    }

    struct Child: StepModel, Decodable {
        let id: UUID
        let type: String
        let content: ExperienceComponent
        let traits: [Experience.Trait]
        let actions: [String: [Experience.Action]]
    }

    init(from decoder: Decoder) throws {
        let modelContainer = try decoder.singleValueContainer()

        // Try decoding a step item first, and if that fails, try a group. If the group also fails, fail the decoding.
        do {
            self = .child(try modelContainer.decode(Child.self))
        } catch {
            self = .group(try modelContainer.decode(Group.self))
        }
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
