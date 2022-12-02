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

        // Add step-group-level traits and top-level-step traits
        switch experience.steps[stepIndex.group] {
        case .group(let stepGroup):
            decomposedTraits.append(contentsOf: DecomposedTraits(traits: traitRegistry.instances(for: stepGroup.traits, level: .group)))
        case .child(let childStep):
            // Decorator traits for a single step are handled below with the stepModels.
            decomposedTraits.append(contentsOf: DecomposedTraits(traits: traitRegistry.instances(for: childStep.traits, level: .step)), ignoringDecorators: true)
        }

        let stepModelsWithTraits: [(step: Experience.Step.Child, decomposedTraits: DecomposedTraits)] = stepModels.map { stepModel in
            let decomposedStepTraits = DecomposedTraits(traits: traitRegistry.instances(for: stepModel.traits, level: .step))
            decomposedStepTraits.propagateDecorators(from: decomposedTraits)
            return (stepModel, decomposedStepTraits)
        }

        let stepControllers: [ExperienceStepViewController] = try stepModelsWithTraits.map {
            let viewModel = ExperienceStepViewModel(step: $0.step, actionRegistry: actionRegistry)
            let stepViewController = ExperienceStepViewController(
                viewModel: viewModel,
                stepState: experience.state(for: $0.step.id),
                notificationCenter: notificationCenter)
            try $0.decomposedTraits.stepDecorating.forEach { try $0.decorate(stepController: stepViewController) }
            return stepViewController
        }

        let pageMonitor = PageMonitor(numberOfPages: stepControllers.count, currentPage: targetPageIndex)
        let containerController = try (decomposedTraits.containerCreating ?? DefaultContainerCreatingTrait())
            .createContainer(for: stepControllers, with: pageMonitor)
        let wrappedContainerViewController = try decomposedTraits.wrapperCreating?.createWrapper(around: containerController) ?? containerController

        let backdropView = UIView()
        decomposedTraits.wrapperCreating?.addBackdrop(backdropView: backdropView, to: wrappedContainerViewController)

        // Apply initial decorators for the target step
        try stepModelsWithTraits[targetPageIndex].decomposedTraits.containerDecorating.forEach {
            try $0.decorate(containerController: containerController)
        }
        try stepModelsWithTraits[targetPageIndex].decomposedTraits.backdropDecorating.forEach {
            try $0.decorate(backdropView: backdropView)
        }

        let stepDecoratingTraitUpdater: (Int, Int) throws -> Void = { newIndex, previousIndex in
            // Remove old decorations
            try stepModelsWithTraits[previousIndex].decomposedTraits.containerDecorating.forEach {
                try $0.undecorate(containerController: containerController)
            }

            try stepModelsWithTraits[previousIndex].decomposedTraits.backdropDecorating.forEach {
                try $0.undecorate(backdropView: backdropView)
            }

            // Add new decorations
            try stepModelsWithTraits[newIndex].decomposedTraits.containerDecorating.forEach {
                try $0.decorate(containerController: containerController)
            }

            try stepModelsWithTraits[newIndex].decomposedTraits.backdropDecorating.forEach {
                try $0.decorate(backdropView: backdropView)
            }
        }

        let unwrappedPresenting = try decomposedTraits.presenting.unwrap(or: TraitError(description: "Presenting capability trait required"))

        return ExperiencePackage(
            traitInstances: decomposedTraits.allTraitInstances,
            stepDecoratingTraitUpdater: stepDecoratingTraitUpdater,
            steps: stepModelsWithTraits.map { $0.0 },
            containerController: containerController,
            wrapperController: wrappedContainerViewController,
            pageMonitor: pageMonitor,
            presenter: { try unwrappedPresenting.present(viewController: wrappedContainerViewController, completion: $0) },
            dismisser: { unwrappedPresenting.remove(viewController: wrappedContainerViewController, completion: $0) }
        )
    }
}

@available(iOS 13.0, *)
extension TraitComposer {
    class DecomposedTraits {
        private(set) var allTraitInstances: [ExperienceTrait]

        private(set) var stepDecorating: [StepDecoratingTrait]
        private(set) var containerCreating: ContainerCreatingTrait?
        private(set) var containerDecorating: [ContainerDecoratingTrait]
        private(set) var backdropDecorating: [BackdropDecoratingTrait]
        private(set) var wrapperCreating: WrapperCreatingTrait?
        private(set) var presenting: PresentingTrait?

        init(traits: [ExperienceTrait]) {
            allTraitInstances = traits

            stepDecorating = traits.compactMap { ($0 as? StepDecoratingTrait) }
            containerCreating = traits.compactMapFirst { ($0 as? ContainerCreatingTrait) }
            containerDecorating = traits.compactMap { ($0 as? ContainerDecoratingTrait) }
            backdropDecorating = traits.compactMap { ($0 as? BackdropDecoratingTrait) }
            wrapperCreating = traits.compactMapFirst { ($0 as? WrapperCreatingTrait) }
            presenting = traits.compactMapFirst { ($0 as? PresentingTrait) }
        }

        /// Combine two `DecomposedTrait` instances. For trait types where a single instance is allowed, take the newer, more specific one.
        ///
        /// Step-level traits will want to set `ignoreDecorators` to avoid contributing their traits to other steps in the group.
        func append(contentsOf newTraits: DecomposedTraits, ignoringDecorators: Bool = false) {
            allTraitInstances.append(contentsOf: newTraits.allTraitInstances)

            if !ignoringDecorators {
                stepDecorating.append(contentsOf: newTraits.stepDecorating)
                containerDecorating.append(contentsOf: newTraits.containerDecorating)
                backdropDecorating.append(contentsOf: newTraits.backdropDecorating)
            }

            containerCreating = newTraits.containerCreating ?? containerCreating
            wrapperCreating = newTraits.wrapperCreating ?? wrapperCreating
            presenting = newTraits.presenting ?? presenting
        }

        func propagateDecorators(from parentTraits: DecomposedTraits) {
            var existingStepDecoratingTypes = Set(stepDecorating.map { type(of: $0).type })
            parentTraits.stepDecorating.reversed().forEach {
                // If we can insert the type into the existing set of types, then it doesn't exist in the array, so propagate it
                if existingStepDecoratingTypes.insert(type(of: $0).type).inserted {
                    stepDecorating.insert($0, at: 0)
                }
            }

            var existingContainerDecoratingTypes = Set(containerDecorating.map { type(of: $0).type })
            parentTraits.containerDecorating.reversed().forEach {
                if existingContainerDecoratingTypes.insert(type(of: $0).type).inserted {
                    containerDecorating.insert($0, at: 0)
                }
            }

            var existingBackdropDecoratingTypes = Set(backdropDecorating.map { type(of: $0).type })
            parentTraits.backdropDecorating.reversed().forEach {
                if existingBackdropDecoratingTypes.insert(type(of: $0).type).inserted {
                    backdropDecorating.insert($0, at: 0)
                }
            }
        }
    }

    class DefaultContainerCreatingTrait: ContainerCreatingTrait {
        static var type: String = "_defaultContainerCreatingTrait"

        let groupID: String? = nil

        init() {}
        required init?(config: [String: Any]?, level: ExperienceTraitLevel) {}

        func createContainer(for stepControllers: [UIViewController], with pageMonitor: PageMonitor) throws -> ExperienceContainerViewController {
            DefaultContainerViewController(stepControllers: stepControllers, pageMonitor: pageMonitor)
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
