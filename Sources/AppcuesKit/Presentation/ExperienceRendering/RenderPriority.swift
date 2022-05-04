//
//  RenderPriority.swift
//  AppcuesKit
//
//  Created by Matt on 2022-05-03.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

internal enum RenderPriority {
    case low
    case normal
}

extension QualifyResponse {
    var renderPriority: RenderPriority {
        switch qualificationReason {
        case .none, .screenView, .pageView: return .low
        case .eventTrigger, .forced: return .normal
        }
    }
}
