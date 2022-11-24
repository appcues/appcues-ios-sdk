//
//  TraitComposer.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-27.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal protocol TraitComposing: AnyObject {
    func package(experience: ExperienceData, stepIndex: Experience.StepIndex) throws -> ExperiencePackage
}

@available(iOS 13.0, *)
internal class TraitComposer: TraitComposing {

    private let traitRegistry: TraitRegistry
    private let actionRegistry: ActionRegistry
    private let notificationCenter: NotificationCenter

    init(container: DIContainer) {
        traitRegistry = container.resolve(TraitRegistry.self)
        actionRegistry = container.resolve(ActionRegistry.self)
        notificationCenter = container.resolve(NotificationCenter.self)
    }

    func package(experience: ExperienceData, stepIndex: Experience.StepIndex) throws -> ExperiencePackage {
        let stepModels: [Experience.Step.Child] = experience.steps[stepIndex.group].items
        let targetPageIndex = stepIndex.item

        if !stepModels.indices.contains(targetPageIndex) {
            let groupID = experience.steps[stepIndex.group].id.uuidString
            let errorMessage = "step group \(groupID) doesn't contain a child step at index \(targetPageIndex)"
            throw ExperienceStateMachine.ExperienceError.step(experience, stepIndex, errorMessage)
        }

        // Start with experience-level traits
        let decomposedTraits = DecomposedTraits(traits: traitRegistry.instances(for: experience.traits, level: .experience))

        // Add step-group-level traits
        switch experience.steps[stepIndex.group] {
        case .group(let stepGroup):
            decomposedTraits.append(contentsOf: DecomposedTraits(traits: traitRegistry.instances(for: stepGroup.traits, level: .group)))
        case .child:
            // Traits for a single step are handled below with the stepModels.
            break
        }

        let stepModelsWithDecorators: [(Experience.Step.Child, [StepDecoratingTrait])] = stepModels.map { stepModel in
            let decomposedStepTraits = DecomposedTraits(traits: traitRegistry.instances(for: stepModel.traits, level: .step))
            decomposedTraits.append(contentsOf: decomposedStepTraits, ignoringDecorators: true)
            return (stepModel, decomposedTraits.stepDecorators + decomposedStepTraits.stepDecorators)
        }

        let stepControllers: [ExperienceStepViewController] = try stepModelsWithDecorators.map { step, decorators in
            let viewModel = ExperienceStepViewModel(step: step, actionRegistry: actionRegistry)
            let stepViewController = ExperienceStepViewController(
                viewModel: viewModel,
                stepState: experience.state(for: experience.steps[stepIndex.group].items[stepIndex.item].id),
                notificationCenter: notificationCenter)
            try decorators.forEach { try $0.decorate(stepController: stepViewController) }
            return stepViewController
        }

        let containerController = try (decomposedTraits.containerCreating ?? DefaultContainerCreatingTrait())
            .createContainer(for: stepControllers, targetPageIndex: targetPageIndex)
        try decomposedTraits.containerDecorating.forEach { try $0.decorate(containerController: containerController) }

        let wrappedContainerViewController = try decomposedTraits.wrapperCreating?.createWrapper(around: containerController) ?? containerController

        if let wrapperCreating = decomposedTraits.wrapperCreating {
            let backdropView = UIView()
            try decomposedTraits.backdropDecorating.forEach { try $0.decorate(backdropView: backdropView) }
            wrapperCreating.addBackdrop(backdropView: backdropView, to: wrappedContainerViewController)
        }

        let unwrappedPresenting = try decomposedTraits.presenting.unwrap(or: TraitError(description: "Presenting capability trait required"))

        return ExperiencePackage(
            traitInstances: decomposedTraits.allTraitInstances,
            steps: stepModelsWithDecorators.map { $0.0 },
            containerController: containerController,
            wrapperController: wrappedContainerViewController,
            presenter: { try unwrappedPresenting.present(viewController: wrappedContainerViewController, completion: $0) },
            dismisser: { unwrappedPresenting.remove(viewController: wrappedContainerViewController, completion: $0) }
        )
    }
}

@available(iOS 13.0, *)
extension TraitComposer {
    class DecomposedTraits {
        private(set) var allTraitInstances: [ExperienceTrait]

        private(set) var stepDecorators: [StepDecoratingTrait]
        private(set) var containerCreating: ContainerCreatingTrait?
        private(set) var containerDecorating: [ContainerDecoratingTrait]
        private(set) var backdropDecorating: [BackdropDecoratingTrait]
        private(set) var wrapperCreating: WrapperCreatingTrait?
        private(set) var presenting: PresentingTrait?

        init(traits: [ExperienceTrait]) {
            allTraitInstances = traits

            stepDecorators = traits.compactMap { ($0 as? StepDecoratingTrait) }
            containerCreating = traits.compactMapFirst { ($0 as? ContainerCreatingTrait) }
            containerDecorating = traits.compactMap { ($0 as? ContainerDecoratingTrait) }
            backdropDecorating = traits.compactMap { ($0 as? BackdropDecoratingTrait) }
            wrapperCreating = traits.compactMapFirst { ($0 as? WrapperCreatingTrait) }
            presenting = traits.compactMapFirst { ($0 as? PresentingTrait) }
        }

        /// Combine two `DecomposedTrait` instances. For trait types where a single instance is allowed, prefer the current one.
        ///
        /// Step-level traits will want to set `ignoreDecorators` to avoid contributing their traits to other steps in the group.
        func append(contentsOf newTraits: DecomposedTraits, ignoringDecorators: Bool = false) {
            allTraitInstances.append(contentsOf: newTraits.allTraitInstances)

            if !ignoringDecorators {
                stepDecorators.append(contentsOf: newTraits.stepDecorators)
            }
            // TODO: move these two into the above if when we're implementing the scoped decorator approach.
            containerDecorating.append(contentsOf: newTraits.containerDecorating)
            backdropDecorating.append(contentsOf: newTraits.backdropDecorating)

            containerCreating = containerCreating ?? newTraits.containerCreating
            wrapperCreating = wrapperCreating ?? newTraits.wrapperCreating
            presenting = presenting ?? newTraits.presenting
        }
    }

    class DefaultContainerCreatingTrait: ContainerCreatingTrait {
        static var type: String = "_defaultContainerCreatingTrait"

        let groupID: String? = nil

        init() {}
        required init?(config: [String: Any]?, level: ExperienceTraitLevel) {}

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
