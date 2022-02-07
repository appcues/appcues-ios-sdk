//
//  TraitComposer.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-27.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

internal protocol TraitComposing: AnyObject {
    func package(experience: Experience, stepIndex: Int) throws -> ExperiencePackage
}

internal class TraitComposer: TraitComposing {

    private let traitRegistry: TraitRegistry
    private let actionRegistry: ActionRegistry

    init(container: DIContainer) {
        traitRegistry = container.resolve(TraitRegistry.self)
        actionRegistry = container.resolve(ActionRegistry.self)
    }

    func package(experience: Experience, stepIndex: Int) throws -> ExperiencePackage {
        var stepModels = [experience.steps[stepIndex]]
        var targetPageIndex = 0

        let experienceTraitInstances: [ExperienceTrait] = traitRegistry.instances(for: experience.traits).filter {
            // Only apply experience-level traits if the trait isn't grouped or target step is part of the group.
            $0.groupID == nil || $0.groupID == experience.steps[stepIndex].traits.groupID
        }

        if let grouper = experienceTraitInstances.compactMapFirst({ $0 as? GroupingTrait }) {
            stepModels = grouper.group(initialStep: stepIndex, in: experience)
            if let pageIndex = stepModels.firstIndex(where: { $0.id == experience.steps[stepIndex].id }) {
                targetPageIndex = pageIndex
            }
        }

        // Decompose all experience-level traits
        let stepDecorators = experienceTraitInstances.compactMap { ($0 as? StepDecoratingTrait) }
        var containerCreating = experienceTraitInstances.compactMapFirst { ($0 as? ContainerCreatingTrait) }
        var containerDecorating = experienceTraitInstances.compactMap { ($0 as? ContainerDecoratingTrait) }
        var backdropDecorating = experienceTraitInstances.compactMap { ($0 as? BackdropDecoratingTrait) }
        var wrapperCreating = experienceTraitInstances.compactMapFirst { ($0 as? WrapperCreatingTrait) }
        var presenting = experienceTraitInstances.compactMapFirst { ($0 as? PresentingTrait) }

        var stepModelsWithDecorators: [(Experience.Step, [StepDecoratingTrait])] = []

        stepModels.forEach { stepModel in
            let stepTraitInstances = traitRegistry.instances(for: stepModel.traits)
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
            steps: stepModelsWithDecorators.map { $0.0 },
            containerController: containerController,
            wrapperController: wrappedContainerViewController,
            presenter: { try unwrappedPresenting.present(viewController: wrappedContainerViewController) },
            dismisser: { unwrappedPresenting.remove(viewController: wrappedContainerViewController) }
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
