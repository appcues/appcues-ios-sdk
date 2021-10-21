//
//  ActionGroup.swift
//  Appcues
//
//  Created by Matt on 2021-10-15.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

/// A `Flow` action step group.
///
/// Action's can't be grouped, but this structure and nomenclature keep it consistent.
internal struct ActionGroup: StepGroup {

    /// An individual action.
    struct Action: Decodable {
        let url: URL
    }

    let id: String
    let index: Int

    let action: Action
}

extension ActionGroup: Decodable {
    /// `flow.attributes.steps.$id.step.attributes` object keys.
    /// These are keys specific to `ActionGroup`.
    private enum AttributeKeys: CodingKey {
        case params
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Flow.StepGroupKeys.self)

        id = try container.decode(String.self, forKey: .id)
        index = try container.decode(Int.self, forKey: .index)

        let stepContainer = try container.nestedContainer(keyedBy: Flow.StepGroupStepKeys.self, forKey: .step)
        let attributeContainer = try stepContainer.nestedContainer(keyedBy: AttributeKeys.self, forKey: .attributes)

        action = try attributeContainer.decode(Action.self, forKey: .params)
    }
}
