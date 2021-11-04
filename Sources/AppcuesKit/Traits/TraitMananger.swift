//
//  TraitMananger.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

internal class TraitMananger {
    private var traits: [ExperienceTrait.Type] = []

    init(container: DIContainer) {
        // Register default container traits
        register(trait: AppcuesModalTrait.self)

        // Register default controller traits
        register(trait: AppcuesSkippableTrait.self)
    }

    func register(trait: ExperienceTrait.Type) {
        traits.append(trait)
    }

    func apply(_ traitModels: [Experience.Trait], to viewController: UIViewController) -> UIViewController {
        apply(controllerExperienceTraits: traitModels, to: viewController)
        return apply(containerExperienceTraits: traitModels, to: viewController)
    }

    private func apply(containerExperienceTraits traitModels: [Experience.Trait], to viewController: UIViewController) -> UIViewController {
        let traitInstances: [ContainerExperienceTrait] = abc(traitModels: traitModels)
        return traitInstances.reduce(viewController) { controller, trait in
            trait.apply(to: controller)
        }
    }

    private func apply(controllerExperienceTraits traitModels: [Experience.Trait], to viewController: UIViewController) {
        let traitInstances: [ControllerExperienceTrait] = abc(traitModels: traitModels)
        traitInstances.forEach { trait in
            trait.apply(to: viewController)
        }
    }

    /// Map and init `ExperienceTrait` instances to apply.
    private func abc<T>(traitModels: [Experience.Trait]) -> [T] {
        traitModels.compactMap { traitModel in
            traits.first { $0.type == traitModel.type }?.init(config: traitModel.config) as? T
        }
    }
}
