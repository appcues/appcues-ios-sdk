//
//  AppcuesExperienceActions.swift
//  AppcuesKit
//
//  Created by Matt on 2024-10-22.
//  Copyright © 2024 Appcues. All rights reserved.
//

import UIKit

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

    @available(iOS 13.0, *)
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

    @available(iOS 13.0, *)
    public func track(name: String, properties: [String: Any]? = nil) {
        enqueue(AppcuesTrackAction(appcues: appcues, eventName: name, attributes: properties))
    }

    @available(iOS 13.0, *)
    public func nextStep() {
        enqueue(AppcuesContinueAction(appcues: appcues, renderContext: renderContext, stepReference: .offset(1)))
    }

    @available(iOS 13.0, *)
    public func previousStep() {
        enqueue(AppcuesContinueAction(appcues: appcues, renderContext: renderContext, stepReference: .offset(-1)))
    }

    @available(iOS 13.0, *)
    public func close(markComplete: Bool = false) {
        enqueue(AppcuesCloseAction(appcues: appcues, renderContext: renderContext, markComplete: markComplete))
    }

    @available(iOS 13.0, *)
    public func updateProfile(properties: [String: Any]) {
        enqueue(AppcuesUpdateProfileAction(appcues: appcues, properties: properties))
    }

    @available(iOS 13.0, *)
    private func enqueue(_ action: AppcuesExperienceAction) {
        guard let actionRegistry = appcues?.container.resolve(ActionRegistry.self) else { return }
        actionRegistry.enqueue(actionInstances: [action]) {}
    }
}
