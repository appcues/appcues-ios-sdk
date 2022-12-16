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

internal enum LossyExperience {
    case decoded(Experience)
    case failed(FailedExperience)

    var parsed: (Experience, error: String?) {
        switch self {
        case let .decoded(experience):
            return (experience, nil)
        case let .failed(failedExperience):
            return (failedExperience.skeletonExperience, failedExperience.error)
        }
    }
}

internal struct FailedExperience: Decodable {
    let id: UUID
    let name: String?
    let type: String?
    let publishedAt: Int?
    var error: String?

    // This is a synthetically generated Experience from the known values of the FailedExperience that
    // did not parse fully from JSON. It is only used for error reporting purposes, generating a flow issue
    // to help diagnose the parsing error.
    var skeletonExperience: Experience {
        Experience(id: id,
                   name: name ?? "",
                   type: type ?? "",
                   publishedAt: publishedAt,
                   traits: [],
                   steps: [],
                   redirectURL: nil,
                   nextContentID: nil)
    }
}

// a helper that deserializes a collection of traits and also enforces that
// no trait types are duplicated within the collection
internal struct TraitCollection: Decodable {
    var traits: [Experience.Trait]

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()

        var traits: [Experience.Trait] = []
        var traitTypes = Set<String>()
        var duplicates = Set<String>()

        if let count = container.count {
            traits.reserveCapacity(count)
        }

        while !container.isAtEnd {
            let trait = try container.decode(Experience.Trait.self)
            if traitTypes.insert(trait.type).inserted {
                // normal case, capture the decoded trait for our resulting array
                traits.append(trait)
            } else {
                // a dupe was found and this will end up causing a decoding error below
                duplicates.insert(trait.type)
            }
        }

        if !duplicates.isEmpty {
            let message = "multiple traits of same type are not supported: \(duplicates.joined(separator: ","))"
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: message))
        }

        self.traits = traits
    }
}

internal protocol PluginDecoder {
    func decode<T: Decodable>(_ type: T.Type) -> T?
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
        let configDecoder: PluginDecoder
    }

    struct Action {
        let trigger: String
        let type: String
        let configDecoder: PluginDecoder
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

    // Post experience actions
    let redirectURL: URL?
    let nextContentID: String?

    /// Unique ID to disambiguate the same experience flowing through the system from different origins.
    let instanceID = UUID()
}

extension Experience: Decodable {
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case publishedAt
        case traits
        case steps
        case redirectURL = "redirectUrl"
        case nextContentID = "nextContentId"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(String.self, forKey: .type)
        publishedAt = try? container.decode(Int.self, forKey: .publishedAt)
        traits = try container.decode(TraitCollection.self, forKey: .traits).traits
        steps = try container.decode([Step].self, forKey: .steps)
        redirectURL = try? container.decode(URL.self, forKey: .redirectURL)
        nextContentID = try? container.decode(String.self, forKey: .nextContentID)
    }
}

extension Experience {
    @available(iOS 13.0, *)
    var postExperienceActions: [ExperienceAction] {
        var actions: [ExperienceAction] = []

        if let redirectURL = redirectURL {
            actions.append(AppcuesLinkAction(url: redirectURL))
        }

        if let nextContentID = nextContentID {
            actions.append(AppcuesLaunchExperienceAction(experienceID: nextContentID,
                                                         trigger: .experienceCompletionAction(fromExperienceID: self.id)))
        }

        return actions
    }
}

extension Experience.Step: Decodable {
    struct Group: StepModel, Decodable {
        let id: UUID
        let type: String
        let children: [Child]
        let traits: [Experience.Trait]
        let actions: [String: [Experience.Action]]

        private enum CodingKeys: CodingKey {
            case id
            case type
            case children
            case traits
            case actions
        }

        // additional constructor used in tests
        init(id: UUID,
             type: String,
             children: [Child],
             traits: [Experience.Trait],
             actions: [String: [Experience.Action]]) {
            self.id = id
            self.type = type
            self.children = children
            self.traits = traits
            self.actions = actions
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(UUID.self, forKey: .id)
            type = try container.decode(String.self, forKey: .type)
            children = try container.decode([Child].self, forKey: .children)
            traits = try container.decode(TraitCollection.self, forKey: .traits).traits
            actions = try container.decode([String: [Experience.Action]].self, forKey: .actions)
        }
    }

    struct Child: StepModel, Decodable {
        let id: UUID
        let type: String
        let content: ExperienceComponent
        let traits: [Experience.Trait]
        let actions: [String: [Experience.Action]]

        private enum CodingKeys: CodingKey {
            case id
            case type
            case content
            case traits
            case actions
        }

        // additional constructor required for ExperienceStepViewModel usage in background content case
        // and used in tests
        init(id: UUID,
             type: String,
             content: ExperienceComponent,
             traits: [Experience.Trait],
             actions: [String: [Experience.Action]]) {
            self.id = id
            self.type = type
            self.content = content
            self.traits = traits
            self.actions = actions
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(UUID.self, forKey: .id)
            type = try container.decode(String.self, forKey: .type)
            content = try container.decode(ExperienceComponent.self, forKey: .content)
            traits = try container.decode(TraitCollection.self, forKey: .traits).traits
            actions = try container.decode([String: [Experience.Action]].self, forKey: .actions)
        }
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
    enum CodingKeys: CodingKey {
        case type
        case config
    }

    private struct TraitDecoder: PluginDecoder {
        private let container: KeyedDecodingContainer<Experience.Trait.CodingKeys>

        init(_ container: KeyedDecodingContainer<Experience.Trait.CodingKeys>) {
            self.container = container
        }

        func decode<T: Decodable>(_ type: T.Type) -> T? {
            try? container.decode(T.self, forKey: .config)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        configDecoder = TraitDecoder(container)
    }
}

extension Experience.Action: Decodable {
    enum CodingKeys: String, CodingKey {
        case trigger = "on"
        case type
        case config
    }

    private struct ActionDecoder: PluginDecoder {
        private let container: KeyedDecodingContainer<Experience.Action.CodingKeys>

        init(_ container: KeyedDecodingContainer<Experience.Action.CodingKeys>) {
            self.container = container
        }

        func decode<T: Decodable>(_ type: T.Type) -> T? {
            try? container.decode(T.self, forKey: .config)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        trigger = try container.decode(String.self, forKey: .trigger)
        type = try container.decode(String.self, forKey: .type)
        configDecoder = ActionDecoder(container)
    }

}
