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

    private weak var appcues: Appcues?
    private let traitRegistry: TraitRegistry
    private let actionRegistry: ActionRegistry
    private let config: Appcues.Config
    private let notificationCenter: NotificationCenter

    init(container: DIContainer) {
        appcues = container.owner
        traitRegistry = container.resolve(TraitRegistry.self)
        actionRegistry = container.resolve(ActionRegistry.self)
        notificationCenter = container.resolve(NotificationCenter.self)
        config = container.resolve(Appcues.Config.self)
    }

    // swiftlint:disable:next function_body_length
    func package(experience: ExperienceData, stepIndex: Experience.StepIndex) throws -> ExperiencePackage {
        let stepModels: [Experience.Step.Child] = experience.steps[stepIndex.group].items
        let targetPageIndex = stepIndex.item

        if !stepModels.indices.contains(targetPageIndex) {
            let groupID = experience.steps[stepIndex.group].id.uuidString
            let errorMessage = "step group \(groupID) doesn't contain a child step at index \(targetPageIndex)"
            throw ExperienceStateMachine.ExperienceError.step(experience, stepIndex, errorMessage)
        }

        // Start with experience-level traits
        let decomposedTraits = DecomposedTraits(traits: traitRegistry.instances(
            for: experience.traits,
            level: .experience,
            renderContext: experience.renderContext
        ))
        var allTraitInstances = decomposedTraits.allTraitInstances

        // Add step-group-level traits and top-level-step traits
        switch experience.steps[stepIndex.group] {
        case .group(let stepGroup):
            let decomposedGroupTraits = DecomposedTraits(traits: traitRegistry.instances(
                for: stepGroup.traits,
                level: .group,
                renderContext: experience.renderContext
            ))
            decomposedTraits.append(contentsOf: decomposedGroupTraits)
            allTraitInstances.append(contentsOf: decomposedGroupTraits.allTraitInstances)
        case .child(let childStep):
            // Decorator traits and allTraitInstances for a single step are handled below with the stepModels.
            decomposedTraits.append(
                contentsOf: DecomposedTraits(traits: traitRegistry.instances(
                    for: childStep.traits,
                    level: .step,
                    renderContext: experience.renderContext
                )),
                ignoringDecorators: true
            )
        }

        let stepModelsWithTraits: [(step: Experience.Step.Child, decomposedTraits: DecomposedTraits)] = stepModels.map { stepModel in
            let decomposedStepTraits = DecomposedTraits(traits: traitRegistry.instances(
                for: stepModel.traits,
                level: .step,
                renderContext: experience.renderContext
            ))
            decomposedStepTraits.propagateDecorators(from: decomposedTraits)
            allTraitInstances.append(contentsOf: decomposedStepTraits.allTraitInstances)
            return (stepModel, decomposedStepTraits)
        }

        let metadataDelegate = AppcuesTraitMetadataDelegate()
        // Ensure the delegate is set for all the traits before we start applying any of them
        allTraitInstances.forEach { $0.metadataDelegate = metadataDelegate }

        let stepControllers: [ExperienceStepViewController] = try stepModelsWithTraits.map {
            let viewModel = ExperienceStepViewModel(
                step: $0.step,
                actionRegistry: actionRegistry,
                renderContext: experience.renderContext,
                config: config,
                appcues: appcues
            )
            let stepViewController = ExperienceStepViewController(
                viewModel: viewModel,
                stepState: experience.state(for: $0.step.id),
                notificationCenter: notificationCenter
            )
            try $0.decomposedTraits.stepDecorating.forEach { try $0.decorate(stepController: stepViewController) }
            return stepViewController
        }

        let pageMonitor = AppcuesExperiencePageMonitor(numberOfPages: stepControllers.count, currentPage: targetPageIndex)
        let containerController = try (decomposedTraits.containerCreating ?? DefaultContainerCreatingTrait())
            .createContainer(for: stepControllers, with: pageMonitor)
        let wrapperController = try decomposedTraits.wrapperCreating?.createWrapper(around: containerController) ?? containerController
        let backdropView = decomposedTraits.wrapperCreating?.getBackdrop(for: wrapperController)

        let stepDecoratingTraitUpdater: (Int, Int?) async throws -> Void = { @MainActor newIndex, previousIndex in
            // Remove old decorations
            if let previousIndex = previousIndex {
                try stepModelsWithTraits[previousIndex].decomposedTraits.containerDecorating.forEach {
                    try $0.undecorate(containerController: containerController)
                }

                if let backdropView = backdropView {
                    try stepModelsWithTraits[previousIndex].decomposedTraits.backdropDecorating.forEach {
                        try $0.undecorate(backdropView: backdropView)
                    }
                }
            }

            // Add new decorations
            try stepModelsWithTraits[newIndex].decomposedTraits.containerDecorating.forEach {
                try $0.decorate(containerController: containerController)
            }

            if let backdropView = backdropView {
                for trait in stepModelsWithTraits[newIndex].decomposedTraits.backdropDecorating {
                    try await trait.decorate(backdropView: backdropView)
                }
            }

            metadataDelegate.publish()
        }

        let presentingTrait = try decomposedTraits.presenting.unwrap(
            or: AppcuesTraitError(description: "Presenting capability trait required")
        )

        return ExperiencePackage(
            traitInstances: decomposedTraits.allTraitInstances,
            stepDecoratingTraitUpdater: stepDecoratingTraitUpdater,
            steps: stepModelsWithTraits.map { $0.0 },
            containerController: containerController,
            wrapperController: wrapperController,
            pageMonitor: pageMonitor,
            presenter: { try presentingTrait.present(viewController: wrapperController, completion: $0) },
            dismisser: { presentingTrait.remove(viewController: wrapperController, completion: $0) }
        )
    }
}

@available(iOS 13.0, *)
extension TraitComposer {
    class DecomposedTraits {
        private(set) var allTraitInstances: [AppcuesExperienceTrait]

        private(set) var stepDecorating: [AppcuesStepDecoratingTrait]
        private(set) var containerCreating: AppcuesContainerCreatingTrait?
        private(set) var containerDecorating: [AppcuesContainerDecoratingTrait]
        private(set) var backdropDecorating: [AppcuesBackdropDecoratingTrait]
        private(set) var wrapperCreating: AppcuesWrapperCreatingTrait?
        private(set) var presenting: AppcuesPresentingTrait?

        init(traits: [AppcuesExperienceTrait]) {
            allTraitInstances = traits

            stepDecorating = traits.compactMap { ($0 as? AppcuesStepDecoratingTrait) }
            containerCreating = traits.compactMapFirst { ($0 as? AppcuesContainerCreatingTrait) }
            containerDecorating = traits.compactMap { ($0 as? AppcuesContainerDecoratingTrait) }
            backdropDecorating = traits.compactMap { ($0 as? AppcuesBackdropDecoratingTrait) }
            wrapperCreating = traits.compactMapFirst { ($0 as? AppcuesWrapperCreatingTrait) }
            presenting = traits.compactMapFirst { ($0 as? AppcuesPresentingTrait) }
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

    class DefaultContainerCreatingTrait: AppcuesContainerCreatingTrait {
        static var type: String = "_defaultContainerCreatingTrait"

        weak var metadataDelegate: AppcuesTraitMetadataDelegate?

        init() {}
        required init?(configuration: AppcuesExperiencePluginConfiguration) {}

        func createContainer(
            for stepControllers: [UIViewController],
            with pageMonitor: AppcuesExperiencePageMonitor
        ) throws -> AppcuesExperienceContainerViewController {
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
