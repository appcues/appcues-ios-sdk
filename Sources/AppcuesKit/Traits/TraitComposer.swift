//
//  TraitComposer.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-27.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

internal protocol TraitComposing: AnyObject {
    func package(experience: Experience, stepIndex: Experience.StepIndex) throws -> ExperiencePackage
}

internal class TraitComposer: TraitComposing {

    private let traitRegistry: TraitRegistry
    private let actionRegistry: ActionRegistry

    init(container: DIContainer) {
        traitRegistry = container.resolve(TraitRegistry.self)
        actionRegistry = container.resolve(ActionRegistry.self)
    }

    func package(experience: Experience, stepIndex: Experience.StepIndex) throws -> ExperiencePackage {
        let stepModels: [Experience.Step.Child] = experience.steps[stepIndex.group].items
        let targetPageIndex = stepIndex.item

        // Experience-level traits
        var allTraitInstances: [ExperienceTrait] = traitRegistry.instances(for: experience.traits)

        // Add step-group-level traits
        switch experience.steps[stepIndex.group] {
        case .group(let stepGroup):
            allTraitInstances.append(contentsOf: traitRegistry.instances(for: stepGroup.traits))
        case .child:
            // Traits for a single step are handled below with the stepModels.
            break
        }

        // Decompose all experience-level traits
        let stepDecorators = allTraitInstances.compactMap { ($0 as? StepDecoratingTrait) }
        var containerCreating = allTraitInstances.compactMapFirst { ($0 as? ContainerCreatingTrait) }
        var containerDecorating = allTraitInstances.compactMap { ($0 as? ContainerDecoratingTrait) }
        var backdropDecorating = allTraitInstances.compactMap { ($0 as? BackdropDecoratingTrait) }
        var wrapperCreating = allTraitInstances.compactMapFirst { ($0 as? WrapperCreatingTrait) }
        var presenting = allTraitInstances.compactMapFirst { ($0 as? PresentingTrait) }

        var stepModelsWithDecorators: [(Experience.Step.Child, [StepDecoratingTrait])] = []

        stepModels.forEach { stepModel in
            let stepTraitInstances = traitRegistry.instances(for: stepModel.traits)
            allTraitInstances.append(contentsOf: stepTraitInstances)
            var stepDecoratingTraits = stepDecorators

            // Decompose step level traits
            stepTraitInstances.forEach { trait in
                if let stepDecoratingTrait = trait as? StepDecoratingTrait {
                    stepDecoratingTraits.append(stepDecoratingTrait)
                }

                containerCreating = containerCreating ?? (trait as? ContainerCreatingTrait)
                if let containerDecoratingTrait = trait as? ContainerDecoratingTrait {
                    containerDecorating.append(containerDecoratingTrait)
                }
                if let backdropDecoratingTrait = trait as? BackdropDecoratingTrait {
                    backdropDecorating.append(backdropDecoratingTrait)
                }
                wrapperCreating = wrapperCreating ?? (trait as? WrapperCreatingTrait)
                presenting = presenting ?? (trait as? PresentingTrait)
            }

            stepModelsWithDecorators.append((stepModel, stepDecoratingTraits))
        }

        let stepControllers: [ExperienceStepViewController] = try stepModelsWithDecorators.map { step, decorators in
            let viewModel = ExperienceStepViewModel(step: step, actionRegistry: actionRegistry)
            let stepViewController = ExperienceStepViewController(viewModel: viewModel)
            try decorators.forEach { try $0.decorate(stepController: stepViewController) }
            return stepViewController
        }

        let containerController = try (containerCreating ?? DefaultContainerCreatingTrait())
            .createContainer(for: stepControllers, targetPageIndex: targetPageIndex)
        try containerDecorating.forEach { try $0.decorate(containerController: containerController) }

        let wrappedContainerViewController = try wrapperCreating?.createWrapper(around: containerController) ?? containerController

        if let wrapperCreating = wrapperCreating {
            let backdropView = UIView()
            try backdropDecorating.forEach { try $0.decorate(backdropView: backdropView) }
            wrapperCreating.addBackdrop(backdropView: backdropView, to: wrappedContainerViewController)
        }

        let unwrappedPresenting = try presenting.unwrap(or: TraitError(description: "Presenting capability trait required"))

        return ExperiencePackage(
            traitInstances: allTraitInstances,
            steps: stepModelsWithDecorators.map { $0.0 },
            containerController: containerController,
            wrapperController: wrappedContainerViewController,
            presenter: { try unwrappedPresenting.present(viewController: wrappedContainerViewController) },
            dismisser: { unwrappedPresenting.remove(viewController: wrappedContainerViewController, completion: $0) }
        )
    }
}

extension TraitComposer {
    struct DefaultContainerCreatingTrait: ContainerCreatingTrait {
        static var type: String = "_defaultContainerCreatingTrait"

        let groupID: String? = nil

        init() {}
        init?(config: [String: Any]?) {}

        func createContainer(for stepControllers: [UIViewController], targetPageIndex: Int) throws -> ExperienceContainerViewController {
            DefaultContainerViewController(stepControllers: stepControllers, targetPageIndex: targetPageIndex)
        }
    }
}

private extension Optional {
    func unwrap(or error: @autoclosure () -> Error) throws -> Wrapped {
        switch self {
        case .some(let value): return value
        case .none: throw error()
        }
    }
}

private extension Array {
    // Functionally the same as Array.compactMap().first(), except returns immediately upon finding the first item.
    func compactMapFirst<ElementOfResult>(_ transform: (Element) throws -> ElementOfResult?) rethrows -> ElementOfResult? {
        for item in self {
            if let result = try transform(item) {
                return result
            }
        }

        return nil
    }
}
