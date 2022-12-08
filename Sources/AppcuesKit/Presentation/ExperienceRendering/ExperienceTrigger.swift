//
//  ExperienceTrigger.swift
//  AppcuesKit
//
//  Created by James Ellis on 12/8/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

internal enum ExperienceTrigger {
    case qualification(reason: String?)
    case experienceCompletionAction(fromExperienceID: UUID?)
    case launchExperienceAction(fromExperienceID: UUID?)
    case showCall
    case deepLink
    case preview
}
