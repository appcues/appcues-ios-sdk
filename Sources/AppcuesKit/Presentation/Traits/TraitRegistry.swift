//
//  TraitRegistry.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

internal class TraitRegistry {
    private var traits: [String: AppcuesExperienceTrait.Type] = [:]
    private weak var appcues: Appcues?

    init(container: DIContainer) {
        self.appcues = container.owner

        // Register default traits
        register(trait: AppcuesStepTransitionAnimationTrait.self)
        register(trait: AppcuesModalTrait.self)
        register(trait: AppcuesTooltipTrait.self)
        register(trait: AppcuesCarouselTrait.self)
        register(trait: AppcuesSkippableTrait.self)
        register(trait: AppcuesBackdropTrait.self)
        register(trait: AppcuesPagingDotsTrait.self)
        register(trait: AppcuesBackgroundContentTrait.self)
        register(trait: AppcuesTargetRectangleTrait.self)
        register(trait: AppcuesTargetElementTrait.self)
        register(trait: AppcuesBackdropKeyholeTrait.self)
        register(trait: AppcuesTargetInteractionTrait.self)
        register(trait: AppcuesEffectsTrait.self)
        register(trait: AppcuesEmbeddedTrait.self)
    }

    @discardableResult
    func register(trait: AppcuesExperienceTrait.Type) -> Bool {
        guard traits[trait.type] == nil else {
            appcues?.config.logger.error("Trait of type %{public}@ is already registered.", trait.type)
            return false
        }

        traits[trait.type] = trait
        return true
    }

    func instances(
        for models: [Experience.Trait],
        level: AppcuesExperiencePluginConfiguration.Level,
        renderContext: RenderContext
    ) -> [AppcuesExperienceTrait] {
        models.compactMap { traitModel in
            traits[traitModel.type]?.init(
                configuration: AppcuesExperiencePluginConfiguration(
                    traitModel.configDecoder,
                    level: level,
                    renderContext: renderContext,
                    appcues: appcues
                )
            )
        }
    }
}
