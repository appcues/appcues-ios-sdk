//
//  HotspotGroup.swift
//  Appcues
//
//  Created by Matt on 2021-10-15.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

/// A `Flow` hotspot step group.
internal struct HotspotGroup: StepGroup {

    /// An individual hotspot.
    struct Step: Decodable {
        let selector: String
    }

    let id: String
    let index: Int

    let steps: [Step]

    let styleID: String
}

extension HotspotGroup: Decodable {
    /// `flow.attributes.steps.$id.step.attributes` object keys.
    /// These are keys specific to `HotspotGroup`.
    private enum AttributeKeys: CodingKey {
        case hotspots
        case style
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Flow.StepGroupKeys.self)

        id = try container.decode(String.self, forKey: .id)
        index = try container.decode(Int.self, forKey: .index)

        let stepContainer = try container.nestedContainer(keyedBy: Flow.StepGroupStepKeys.self, forKey: .step)
        let attributeContainer = try stepContainer.nestedContainer(keyedBy: AttributeKeys.self, forKey: .attributes)

        steps = try attributeContainer.decode([Step].self, forKey: .hotspots)
        styleID = try attributeContainer.decode(String.self, forKey: .style)
    }
}
