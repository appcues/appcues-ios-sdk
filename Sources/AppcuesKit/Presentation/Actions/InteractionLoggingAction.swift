//
//  InteractionLoggingAction.swift
//  AppcuesKit
//
//  Created by Matt on 2022-10-06.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

internal protocol InteractionLoggingAction {
    var category: String { get }
    var destination: String { get }
}

// MARK: - Implementations
// These are the actions that can define the step_interaction analytic values.

@available(iOS 13.0, *)
extension AppcuesLinkAction: InteractionLoggingAction {
    var category: String { "link" }
    var destination: String { url.absoluteString }
}

@available(iOS 13.0, *)
extension AppcuesLaunchExperienceAction: InteractionLoggingAction {
    var category: String { "internal" }
    var destination: String { experienceID }
}

@available(iOS 13.0, *)
extension AppcuesContinueAction: InteractionLoggingAction {
    var category: String { "internal" }
    var destination: String { stepReference.description }
}

@available(iOS 13.0, *)
extension AppcuesCloseAction: InteractionLoggingAction {
    var category: String { "internal" }
    var destination: String { "end-experience" }
}

extension StepReference {
    var description: String {
        switch self {
        case .index(let index):
            return "#\(index)"
        case .offset(let offset):
            return offset > 0 ? "+\(offset)" : "\(offset)"
        case .stepID(let stepID):
            return stepID.uuidString
        }
    }
}
