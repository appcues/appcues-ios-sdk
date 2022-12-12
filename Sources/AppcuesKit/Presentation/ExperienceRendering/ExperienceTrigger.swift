//
//  ExperienceTrigger.swift
//  AppcuesKit
//
//  Created by James Ellis on 12/8/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

internal enum ExperienceTrigger {
    case qualification(reason: QualifyResponse.QualificationReason?)
    case experienceCompletionAction(fromExperienceID: UUID?)
    case launchExperienceAction(fromExperienceID: UUID?)
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
        case .experienceCompletionAction, .launchExperienceAction, .showCall, .deepLink, .preview:
            return true
        }
    }
}
