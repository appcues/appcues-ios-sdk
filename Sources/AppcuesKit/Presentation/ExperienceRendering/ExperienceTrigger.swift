//
//  ExperienceTrigger.swift
//  AppcuesKit
//
//  Created by James Ellis on 12/8/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

internal enum ExperienceTrigger: Equatable {
    case qualification(reason: QualifyResponse.QualificationReason?)
    case experienceCompletionAction(fromExperienceID: UUID?)
    case launchExperienceAction(fromExperienceID: UUID?)
    case pushNotification(notificationID: String)
    case showCall
    case deepLink
    case preview

    // for pre-step navigation actions - only allow these to execute if this experience is being launched for some
    // other reason than qualification (i.e. deep links, preview, manual show). For any qualified experience, the initial
    // starting state of the experience is determined solely by flow settings determining the trigger
    // (i.e. trigger on certain screen).
    var shouldNavigateBeforeRender: Bool {
        switch self {
        case .qualification:
            return false
        case .experienceCompletionAction, .launchExperienceAction, .pushNotification, .showCall, .deepLink, .preview:
            return true
        }
    }

    var property: String? {
        switch self {
        case .qualification(let reason): return reason?.rawValue
        case .experienceCompletionAction: return "experience_completion_action"
        case .launchExperienceAction: return "launch_action"
        case .pushNotification: return "push_notification"
        case .showCall: return "show_call"
        case .deepLink: return "deep_link"
        case .preview: return nil
        }
    }
}
