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
@available(iOS 13.0, *)
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
        if case .failure(.step(_, _, _, recoverable: true)) = result {
            startRetryHandler()
        }

        // recovery observer never stops observing
        return false
    }

    private func startRetryHandler() {
        AppcuesScrollViewDelegate.shared.attach(using: self)
    }
}
