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

    enum FlowType: String, Decodable {
        // TODO: What are the other possible states?
        case journey

    }

    let id: String
    let name: String
    let type: FlowType
    let createdAt: Date
    let updatedAt: Date
    let context: [String: Any]

    let state: State
    let steps: [StepGroup]
}

extension Flow: Decodable {
    /// Values for mapping `flow.attributes.steps.$id.step_type`
    private enum StepType: String, Decodable {
        case modalGroup = "modal"
        case hotspotGroup = "hotspot-group"
        case action
    }

    /// `flow` object keys.
    private enum CodingKeys: CodingKey {
        case id
        case name
        case type
        case createdAt
        case updatedAt
        case context
        case attributes
    }

    /// `flow.attributes` object keys.
    private enum AttributeKeys: CodingKey {
        case state
        case steps
    }

    /// `flow.attributes.steps` dynamic object keys.
    private struct DynamicStepCodingKeys: CodingKey {
        var stringValue: String

        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        var intValue: Int?

        init?(intValue: Int) {
            // No int keys supported
            return nil
        }
    }

    /// `flow.attributes.steps.$id` object keys.
    /// Some of these keys are only used in the `StepGroup` conformees.
    enum StepGroupKeys: CodingKey {
        case stepType

        case id
        case index
        case step
    }

    /// `flow.attributes.steps.$id.step` object keys.
    /// Only used in the `StepGroup` conformees.
    enum StepGroupStepKeys: CodingKey {
        case attributes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(FlowType.self, forKey: .type)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        context = try container.decode([String: Any].self, forKey: .context)

        let attributesContainer = try container.nestedContainer(keyedBy: AttributeKeys.self, forKey: .attributes)
        state = try attributesContainer.decode(State.self, forKey: .state)

        // Steps are in an object keyed by the step ID.
        // 1. Dynamically get the keys.
        // 2. Figure out what type the step is.
        // 3. Try parsing that type, and add it to the partial list.
        // 4. Sort the partial (now complete) list and assign to `steps`.
        var partialStepGroups: [StepGroup] = []

        // 1.
        let stepContainer = try attributesContainer.nestedContainer(keyedBy: DynamicStepCodingKeys.self, forKey: .steps)

        for key in stepContainer.allKeys {
            // 2.
            let partialContainer = try stepContainer.nestedContainer(keyedBy: StepGroupKeys.self, forKey: key)
            let stepType = try partialContainer.decode(StepType.self, forKey: .stepType)

            // 3.
            switch stepType {
            case .modalGroup:
                partialStepGroups.append(try stepContainer.decode(ModalGroup.self, forKey: key))
            case .hotspotGroup:
                partialStepGroups.append(try stepContainer.decode(HotspotGroup.self, forKey: key))
            case .action:
                partialStepGroups.append(try stepContainer.decode(ActionGroup.self, forKey: key))
            }
        }

        // 4.
        steps = partialStepGroups.sorted { $0.index < $1.index }
    }
}
