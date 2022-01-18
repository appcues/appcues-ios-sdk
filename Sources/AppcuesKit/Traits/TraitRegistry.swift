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
        register(trait: AppcuesModalGroupTrait.self)
        register(trait: AppcuesStickyContentTrait.self)
    }

    func register(trait: ExperienceTrait.Type) {
        traits.append(trait)
    }

    func apply(_ traitModels: [Experience.Trait], toStep stepController: ExperienceStepViewController) {
        traitModels
        .compactMap { traitModel in
            traits.first { $0.type == traitModel.type }?.init(config: traitModel.config) as? ControllerTrait
        }
        .forEach { trait in
            trait.apply(to: stepController)
        }
    }

    func apply(_ traitModels: [Experience.Trait], toContainer containerController: ExperiencePagingViewController) -> UIViewController {
        traitModels
        .compactMap { traitModel in
            traits.first { $0.type == traitModel.type }?.init(config: traitModel.config) as? ContainerTrait
        }
        .reduce(containerController) { wrappingController, trait in
            trait.apply(to: containerController, wrappedBy: wrappingController)
        }
    }
}
