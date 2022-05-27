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
    private var traits: [String: ExperienceTrait.Type] = [:]

    init(container: DIContainer) {
        // Register default traits
        register(trait: AppcuesModalTrait.self)
        register(trait: AppcuesCarouselTrait.self)
        register(trait: AppcuesStickyContentTrait.self)
        register(trait: AppcuesSkippableTrait.self)
        register(trait: AppcuesBackdropTrait.self)
        register(trait: AppcuesPagingDotsTrait.self)

        register(trait: ExperimentalBlurBackdropTrait.self)
        register(trait: ExperimentalConfettiTrait.self)
        register(trait: ExperimentalGradientTrait.self)
        register(trait: ExperimentalNavigationTreeTrait.self)
        register(trait: ExperimentalNavigationTitleTrait.self)
        register(trait: ExperimentalTabBarTrait.self)
        register(trait: ExperimentalTabBarItemTrait.self)
        register(trait: ExperimentalTooltipTrait.self)
        register(trait: ExperimentalVibrancyTrait.self)
    }

    func register(trait: ExperienceTrait.Type) {
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

    func instances(for models: [Experience.Trait]) -> [ExperienceTrait] {
        models.compactMap { traitModel in
            traits[traitModel.type]?.init(config: traitModel.config)
        }
    }
}
