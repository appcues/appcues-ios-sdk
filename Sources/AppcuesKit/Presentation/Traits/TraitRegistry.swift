//
//  TraitRegistry.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class TraitRegistry {
    private var traits: [String: AppcuesExperienceTrait.Type] = [:]

    init(container: DIContainer) {
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
    }

    func register(trait: AppcuesExperienceTrait.Type) {
        guard traits[trait.type] == nil else {
            #if DEBUG
            if ProcessInfo.processInfo.environment["XCTestBundlePath"] == nil {
                assertionFailure("Trait of type \(trait.type) is already registered.")
            }
            #endif
            return
        }

        traits[trait.type] = trait
    }

    func instances(for models: [Experience.Trait], level: AppcuesExperiencePluginConfiguration.Level) -> [AppcuesExperienceTrait] {
        models.compactMap { traitModel in
            traits[traitModel.type]?.init(configuration: AppcuesExperiencePluginConfiguration(traitModel.configDecoder, level: level))
        }
    }
}
