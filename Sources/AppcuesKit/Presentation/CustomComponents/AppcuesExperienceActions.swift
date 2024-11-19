//
//  AppcuesExperienceActions.swift
//  AppcuesKit
//
//  Created by Matt on 2024-10-22.
//  Copyright © 2024 Appcues. All rights reserved.
//

import UIKit

/// Action options for a custom component to invoke.
public class AppcuesExperienceActions {
    private weak var appcues: Appcues?
    private let renderContext: RenderContext
    private let identifier: String

    var actions: [Experience.Action]?

    init(appcues: Appcues?, renderContext: RenderContext, identifier: String) {
        self.appcues = appcues
        self.renderContext = renderContext
        self.identifier = identifier
    }

    /// Trigger the actions associated with the custom component in the Appcues Mobile Builder.
    public func triggerBlockActions() {
        guard let actions = actions, let actionRegistry = appcues?.container.resolve(ActionRegistry.self) else { return }
        actionRegistry.enqueue(
            actionModels: actions,
            level: .step,
            renderContext: renderContext,
            interactionType: "Button Tapped",
            viewDescription: "Custom component \(identifier)"
        )
    }

    /// Track a custom event for an action taken by a user.
    /// - Parameters:
    ///   - name: Name of the event.
    ///   - properties: Optional properties that provide additional context about the event.
    public func track(name: String, properties: [String: Any]? = nil) {
        enqueue(AppcuesTrackAction(appcues: appcues, eventName: name, attributes: properties))
    }

    /// Advance the flow to the next step. If the flow is on its final step, the flow will dismiss as completed.
    public func nextStep() {
        enqueue(AppcuesContinueAction(appcues: appcues, renderContext: renderContext, stepReference: .offset(1)))
    }

    /// Navigate the flow to the previous step. If the flow is on its initial step, nothing will happen.
    public func previousStep() {
        enqueue(AppcuesContinueAction(appcues: appcues, renderContext: renderContext, stepReference: .offset(-1)))
    }

    /// Dismiss the flow.
    /// - Parameter markComplete: Whether the flow should be marked as complete for analytics purposes. Defaults to `false`.
    public func close(markComplete: Bool = false) {
        enqueue(AppcuesCloseAction(appcues: appcues, renderContext: renderContext, markComplete: markComplete))
    }

    /// Update the Appcues profile of the current user.
    /// - Parameter properties: Properties to add to the Appcues profile of the current user.
    public func updateProfile(properties: [String: Any]) {
        enqueue(AppcuesUpdateProfileAction(appcues: appcues, properties: properties))
    }

    private func enqueue(_ action: AppcuesExperienceAction) {
        guard let actionRegistry = appcues?.container.resolve(ActionRegistry.self) else { return }
        actionRegistry.enqueue(actionInstances: [action]) {}
    }
}
