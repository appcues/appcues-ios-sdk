//
//  ModalGroup.swift
//  Appcues
//
//  Created by Matt on 2021-10-15.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

/// A `Flow` modal step group.
internal struct ModalGroup: StepGroup {

    /// An individual modal.
    struct Step: Decodable, Hashable {
        let html: String
    }

    enum Pattern: String, Decodable {
        case modal
        case fullscreen
        case shorty
    }

    let id: String
    let index: Int

    let steps: [Step]

    let pattern: Pattern
    let styleID: String
    let skippable: Bool
    let showProgress: Bool
}

extension ModalGroup: Decodable {
    /// `flow.attributes.steps.$id.step.attributes` object keys.
    /// These are keys specific to `ModalGroup`.
    private enum AttributeKeys: CodingKey {
        case steps
        case patternType
        case style
        case skippable
        case isProgressBarHidden
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Flow.StepGroupKeys.self)

        id = try container.decode(String.self, forKey: .id)
        index = try container.decode(Int.self, forKey: .index)

        let stepContainer = try container.nestedContainer(keyedBy: Flow.StepGroupStepKeys.self, forKey: .step)
        let attributeContainer = try stepContainer.nestedContainer(keyedBy: AttributeKeys.self, forKey: .attributes)

        steps = try attributeContainer.decode([Step].self, forKey: .steps)
        pattern = try attributeContainer.decode(Pattern.self, forKey: .patternType)
        // TODO: Style apparently can be null if it's the default? We need to know how to get the fallback value here.
        styleID = try attributeContainer.decode(String.self, forKey: .style)
        skippable = try attributeContainer.decode(Bool.self, forKey: .skippable)
        showProgress = !(try attributeContainer.decode(Bool.self, forKey: .isProgressBarHidden))
    }
}
