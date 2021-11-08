//
//  TraitRegistry.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

internal class TraitRegistry {
    private var traits: [ExperienceTrait.Type] = []

    init(container: DIContainer) {
        // Register default traits
        register(trait: AppcuesModalTrait.self)
        register(trait: AppcuesSkippableTrait.self)
    }

    func register(trait: ExperienceTrait.Type) {
        traits.append(trait)
    }

    func apply(_ traitModels: [Experience.Trait], to experienceController: UIViewController) -> UIViewController {
        traitModels.compactMap { traitModel in
            traits.first { $0.type == traitModel.type }?.init(config: traitModel.config)
        }
        .reduce(experienceController) { wrappingController, trait in
            trait.apply(to: experienceController, containedIn: wrappingController)
        }
    }
}
