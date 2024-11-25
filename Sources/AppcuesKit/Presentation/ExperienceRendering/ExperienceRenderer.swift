//
//  ExperienceRenderer.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-20.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

internal protocol ExperienceRendering: AnyObject {
    func start(owner: StateMachineOwning, forContext context: RenderContext) async throws
    func processAndShow(qualifiedExperiences: [ExperienceData], reason: ExperienceTrigger) async throws
    func processAndShow(experience: ExperienceData) async throws
    func show(step stepRef: StepReference, inContext context: RenderContext) async throws
    func dismiss(inContext context: RenderContext, markComplete: Bool) async throws
    func experienceData(forContext context: RenderContext) -> ExperienceData?
    func stepIndex(forContext context: RenderContext) -> Experience.StepIndex?
    func owner(forContext context: RenderContext) -> StateMachineOwning?
    func resetAll() async throws
}

internal enum RenderContext: Hashable, CustomStringConvertible {
    case modal
    case embed(frameID: String)

    var frameID: String? {
        switch self {
        case .modal:
            return nil
        case .embed(let frameID):
            return frameID
        }
    }

    var description: String {
        switch self {
        case .modal:
            return "modal"
        case .embed(let frameID):
            return "frame \(frameID)"
        }
    }
}

internal enum ExperienceRendererError: Error {
    case renderDeferred(RenderContext, Experience)
    case noStateMachine
    case experimentControl
}

internal class ExperienceRenderer: ExperienceRendering, StateMachineOwning {

    // Conformance to `StateMachineOwning`.
    /// State machine for `RenderContext.modal`
    var stateMachine: ExperienceStateMachine?
    var renderContext: RenderContext?

    private var stateMachines = StateMachineDirectory()
    private var pendingPreviewExperiences: [RenderContext: ExperienceData] = [:]
    private var potentiallyRenderableExperiences: [RenderContext: [ExperienceData]] = [:]
    private let analyticsObserver: ExperienceStateMachine.AnalyticsObserver
    private let stepRecoveryObserver: StepRecoveryObserver
    private weak var appcues: Appcues?
    private let config: Appcues.Config

    init(container: DIContainer) {
        self.appcues = container.owner
        self.config = container.resolve(Appcues.Config.self)

        // two items below are not registered/resolved directly from container as they
        // are considered private implementation details of the ExperienceRenderer - helpers.
        let stateMachine = ExperienceStateMachine(container: container)
        self.stateMachine = stateMachine
        self.analyticsObserver = ExperienceStateMachine.AnalyticsObserver(container: container)
        self.stepRecoveryObserver = StepRecoveryObserver(stateMachine: stateMachine)

        stateMachines[ownerFor: .modal] = self
    }

    func start(owner: StateMachineOwning, forContext context: RenderContext) async throws {
        guard let container = appcues?.container else { return }

        // If there's already a frame for the context, reset it back to its unregistered state.
        if let existingFrameView = stateMachines[ownerFor: context] as? AppcuesFrameView {
            await existingFrameView.reset()
        }

        // If the machine being started is already registered for a different context,
        // reset it back to its unregistered state before potentially showing new content.
        if owner.stateMachine != nil, let frameView = owner as? AppcuesFrameView {
            await frameView.reset()
        }

        owner.stateMachine = ExperienceStateMachine(container: container)
        stateMachines[ownerFor: context] = owner

        // A preview experience takes priority over qualified experiences.
        if let pendingPreviewExperience = pendingPreviewExperiences[context] {
            try await show(experience: pendingPreviewExperience)
        } else if let pendingExperiences = potentiallyRenderableExperiences[context] {
            try await show(qualifiedExperiences: pendingExperiences)
        }
    }

    func processAndShow(qualifiedExperiences: [ExperienceData], reason: ExperienceTrigger) async throws {
        let shouldClearCache = reason == .qualification(reason: .screenView)
        if shouldClearCache {
            potentiallyRenderableExperiences = [:]
            stateMachines.cleanup()
        }

        // Add new experiences, replacing any existing ones
        let grouped = Dictionary(grouping: qualifiedExperiences) { $0.renderContext }
        potentiallyRenderableExperiences = potentiallyRenderableExperiences.merging(grouped)

        // Try in each render context and don't let one failure block the others
        var errors: [Error] = []
        for (_, qualifiedExperiences) in potentiallyRenderableExperiences {
            do {
                try await show(qualifiedExperiences: qualifiedExperiences)
            } catch {
                errors.append(error)
            }
        }

        // No caching required for modals since they can't be lazy-loaded.
        potentiallyRenderableExperiences.removeValue(forKey: .modal)

        if let error = errors.first {
            throw error
        }
    }

    func processAndShow(experience: ExperienceData) async throws {
        let reason = experience.trigger

        if reason == .preview {
            pendingPreviewExperiences[experience.renderContext] = experience
        } else if experience.renderContext != .modal {
            // No caching required for modals since they can't be lazy-loaded.
            potentiallyRenderableExperiences[experience.renderContext] = [experience]
        }

        try await show(experience: experience)
    }

    private func show(experience: ExperienceData) async throws {
        guard let stateMachine = stateMachines[experience.renderContext] else {
            analyticsObserver.trackRecoverableError(
                experience: experience,
                message: "no render context for \(experience.renderContext.description)"
            )
            throw ExperienceRendererError.renderDeferred(experience.renderContext, experience.model)
        }

        guard experience.instanceID != stateMachine.state.currentExperienceData?.instanceID else {
            // This experience is already showing
            return
        }

        guard experience.experiment?.shouldExecute ?? true else {
            // if we get here, it means we did have an experiment, but it was the control group and
            // we should not continue. So track experiment_entered analytics for it (always)..
            track(experiment: experience.experiment)
            // and exit early
            throw ExperienceRendererError.experimentControl
        }

        if experience.priority == .normal && stateMachine.state != .idling {
            try await dismiss(inContext: experience.renderContext, markComplete: false)
        }

        // all the pre-requisite checks are complete - start the experience
        try await start(experience, in: stateMachine)
    }

    private func start(_ experience: ExperienceData, in stateMachine: ExperienceStateMachine) async throws {
        // if we get here, either we did not have an experiment, or it is active and did not exit early (not control group).
        // if an active experiment does exist, it should now track the experiment_entered analytic
        track(experiment: experience.experiment)

        // and only add the observer if the state machine is idling, otherwise there's already another experience in-flight
        if stateMachine.state == .idling {
            // we always add an analytics observer, it will internally filter out unpublished flows (builder previews)
            stateMachine.addObserver(analyticsObserver)

            if experience.renderContext == .modal && config.enableStepRecoveryObserver {
                // add recovery observer - on recoverable step errors, initiate recovery and retry
                stateMachine.addObserver(stepRecoveryObserver)
            }
        }

        analyticsObserver.trackErrorRecovery(ifErrorOn: experience)
        stateMachine.clientAppcuesPresentationDelegate = appcues?.presentationDelegate
        stateMachine.clientAppcuesDelegate = appcues?.experienceDelegate

        try await stateMachine.transition(.startExperience(experience))
    }

    private func show(qualifiedExperiences: [ExperienceData]) async throws {
        guard let experience = qualifiedExperiences.first else {
            // If given an empty list of qualified experiences, complete with a success because this function has completed without error.
            // This function only recurses on a non-empty case, so this block only applies to the initial external call.
            return
        }

        do {
            try await show(experience: experience)
        } catch ExperienceRendererError.noStateMachine {
            // If there's no state machine available, there's no point in trying the remaining experiences for the same context
            throw ExperienceRendererError.noStateMachine
        } catch {
            let remainingExperiences = qualifiedExperiences.dropFirst()
            if remainingExperiences.isEmpty {
                throw error
            } else {
                try await self.show(qualifiedExperiences: Array(remainingExperiences))
            }
        }
    }

    func show(step stepRef: StepReference, inContext context: RenderContext) async throws {
        guard let stateMachine = stateMachines[context] else {
            return
        }

        try await stateMachine.transition(.startStep(stepRef))
    }

    func dismiss(inContext context: RenderContext, markComplete: Bool) async throws {
        guard let stateMachine = stateMachines[context] else {
            throw ExperienceRendererError.noStateMachine
        }

        do {
            try await stateMachine.transition(.endExperience(markComplete: markComplete))
            pendingPreviewExperiences.removeValue(forKey: context)
            potentiallyRenderableExperiences.removeValue(forKey: context)
        } catch let error as ExperienceStateMachine.InvalidTransition {
            // Handle dismissing an experience that's in the process of presenting a step group.
            switch error.fromState {
            case .beginningExperience, .beginningStep:
                // Want to wait for .renderingStep case to dismiss and return
                for await currentState in stateMachine.stateStream {
                    if case .renderingStep = currentState {
                        break
                    }
                }
                // Retry now that we're in a valid state
                try await dismiss(inContext: context, markComplete: markComplete)
            default:
                throw error
            }
        }
    }

    func experienceData(forContext context: RenderContext) -> ExperienceData? {
        stateMachines[context]?.state.currentExperienceData
    }

    func stepIndex(forContext context: RenderContext) -> Experience.StepIndex? {
        stateMachines[context]?.state.currentStepIndex
    }

    func owner(forContext context: RenderContext) -> StateMachineOwning? {
        stateMachines[ownerFor: context]
    }

    func resetAll() async {
        pendingPreviewExperiences.removeAll()
        potentiallyRenderableExperiences.removeAll()

        await stateMachines.asyncForEach { _, stateMachineOwning in
            try? await stateMachineOwning.reset()
        }
    }

    /// Reset only the owned `Self.stateMachine` instance in conformance to `StateMachineOwning`.
    func reset() async {
        stateMachine?.removeAnalyticsObserver()
        try? await dismiss(inContext: .modal, markComplete: false)
    }

    private func track(experiment: Experiment?) {
        guard let experiment = experiment,
              let analyticsPublisher = appcues?.container.resolve(AnalyticsPublishing.self) else {
            return
        }

        analyticsPublisher.publish(TrackingUpdate(
            type: .event(name: "appcues:experiment_entered", interactive: false),
            properties: [
                "experimentId": experiment.experimentID.appcuesFormatted,
                "experimentGroup": experiment.group,
                "experimentExperienceId": experiment.experienceID.appcuesFormatted,
                "experimentContentType": experiment.contentType,
                "experimentGoalId": experiment.goalID
            ],
            isInternal: true
        ))
    }
}
