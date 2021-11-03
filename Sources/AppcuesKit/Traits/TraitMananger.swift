//
//  TraitMananger.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

internal class TraitMananger {
    var containerExperienceTraits: [ContainerExperienceTrait.Type] = []
    var controllerExperienceTraits: [ControllerExperienceTrait.Type] = []

    init(container: DIContainer) {
        // Register default container traits
        register(trait: AppcuesModalTrait.self)

        // Register default controller traits
        register(trait: AppcuesSkippableTrait.self)
    }

    func register(trait: ExperienceTrait.Type) {
        if let containerExperienceTrait = trait as? ContainerExperienceTrait.Type {
            containerExperienceTraits.append(containerExperienceTrait)
        }

        if let controllerExperienceTrait = trait as? ControllerExperienceTrait.Type {
            controllerExperienceTraits.append(controllerExperienceTrait)
        }
    }

    /// Map and init `ExperienceTrait` instances to apply.
    ///
    /// Non `ContainerExperienceTrait`'s in the `traitModels` array will be skipped.
    func apply(containerExperienceTraits traitModels: [Experience.Trait], to viewController: UIViewController) -> UIViewController {
        traitModels.compactMap { traitModel in
            return containerExperienceTraits
                .first { $0.type == traitModel.type }?
                .init(config: traitModel.config)
        }
        .reduce(viewController) { controller, trait in
            trait.apply(to: controller)
        }
    }

    /// Map and init `ExperienceTrait` instances to apply.
    ///
    /// Non `ControllerExperienceTrait`'s in the `traitModels` array will be skipped.
    func apply(controllerExperienceTraits traitModels: [Experience.Trait], to viewController: UIViewController) {
        traitModels.compactMap { traitModel in
            return controllerExperienceTraits
                .first { $0.type == traitModel.type }?
                .init(config: traitModel.config)
        }
        .forEach { trait in
            trait.apply(to: viewController)
        }
    }
}
