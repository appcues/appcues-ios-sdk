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

    var properties: [String: Any] {
        switch self {
        case let .qualification(reason):
            return [
                "triggeredBy": "qualification",
                "qualificationReason": reason
            ].compactMapValues { $0 }
        case let .experienceCompletionAction(fromExperienceID):
            return [
                "triggeredBy": "experienceCompletionAction",
                "triggeredByExperienceId": fromExperienceID?.uuidString.lowercased()
            ].compactMapValues { $0 }
        case let .launchExperienceAction(fromExperienceID):
            return [
                "triggeredBy": "launchExperienceAction",
                "triggeredByExperienceId": fromExperienceID?.uuidString.lowercased()
            ].compactMapValues { $0 }
        case .showCall:
            return ["triggeredBy": "showCall"]
        case .deepLink:
            return ["triggeredBy": "deepLink"]
        case .preview:
            return [:]
        }

    }
}
