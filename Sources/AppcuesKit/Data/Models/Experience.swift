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
}

extension Experience {
    @available(iOS 13.0, *)
    var postExperienceActions: [ExperienceAction] {
        var actions: [ExperienceAction] = []

        if let redirectURL = redirectURL {
            actions.append(AppcuesLinkAction(url: redirectURL))
        }

        if let nextContentID = nextContentID {
            actions.append(AppcuesLaunchExperienceAction(experienceID: nextContentID))
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
