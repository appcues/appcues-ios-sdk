//
//  StepRecoveryObserver.swift
//  AppcuesKit
//
//  Created by James Ellis on 12/6/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import Foundation

// This class is only used by the Modal RenderContext (modals and tooltips)
// to detect recoverable step errors and attempt to retry when scroll changes
// are observed. It hooks into the AppcuesScrollViewDelegate, which receives
// scroll updates from the UIScrollView implementations in the app via
// method swizzling.
internal class StepRecoveryObserver: ExperienceStateObserver {

    private let stateMachine: ExperienceStateMachine

    init(stateMachine: ExperienceStateMachine) {
        self.stateMachine = stateMachine
    }

    func scrollEnded() {
        stopRetryHandler() // stop now, if this next retry fails, it will start over again
        try? stateMachine.transition(.retry)
    }

    func stopRetryHandler() {
        AppcuesScrollViewDelegate.shared.detach()
    }

    func evaluateIfSatisfied(result: ExperienceStateObserver.StateResult) -> Bool {
        switch result {
        case .failure(.step(_, _, _, recoverable: true)):
            // a recoverable step error has been observed, so we begin attempting
            // recovery - this will attach a listener to scroll changes in the app
            // to see if layout changes make this experience presentable
            startRetryHandler()
        case .success(.idling):
            // if the machine goes back to idling, this means that any experience
            // that was in a retry state was fully dismissed, or potentially a new
            // experience has been queued up to start in its place - remove any
            // existing retry handler to stop attempting recovery
            stopRetryHandler()
        default:
            break
        }

        // recovery observer never stops observing
        return false
    }

    private func startRetryHandler() {
        AppcuesScrollViewDelegate.shared.attach(using: self)
    }
}
