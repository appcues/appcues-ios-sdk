//
//  ExperienceTrigger.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/27/22.
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
    case unknown

    private var triggerName: String? {
        switch self {
        case .qualification:
            return "qualification"
        case .experienceCompletionAction:
            return "experienceCompletionAction"
        case .launchExperienceAction:
            return "launchExperienceAction"
        case .showCall:
            return "showCall"
        case .deepLink:
            return "deepLink"
        case .preview, .unknown:
            return nil
        }
    }

    private var additionalProperties: [String: Any?] {
        switch self {
        case let .qualification(reason):
            return [
                "qualificationReason": reason
            ]
        case .experienceCompletionAction(let fromExperienceID),
                .launchExperienceAction(let fromExperienceID):
            return [
                "triggeredByExperienceId": fromExperienceID?.uuidString.lowercased()
            ]
        default:
            return [:]
        }
    }

    var properties: [String: Any] {
        return [ "triggeredBy": triggerName ].merging(additionalProperties) { _, new in new }.compactMapValues { $0 }
    }
}
