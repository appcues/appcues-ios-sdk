//
//  StructuredLifecycleProperties.swift
//  AppcuesKit
//
//  Created by Matt on 2023-10-16.
//  Copyright © 2023 Appcues. All rights reserved.
//

import Foundation

internal struct StructuredLifecycleProperties: Equatable {
    let type: Events.Experience
    let experienceID: UUID
    let experienceName: String
    let experienceInstanceID: UUID
    let frameID: String?
    let stepID: UUID?
    let stepIndex: Experience.StepIndex?

    let errorID: UUID?
    let message: String?

    init?(update: TrackingUpdate) {
        guard let type = Events.Experience(trackingType: update.type) else { return nil }

        guard let experienceID = UUID(uuidString: update.properties?["experienceId"] as? String ?? ""),
              let experienceName = update.properties?["experienceName"] as? String,
              let experienceInstanceID = UUID(uuidString: update.properties?["experienceInstanceId"] as? String ?? "") else {
            return nil
        }

        self.type = type
        self.experienceID = experienceID
        self.experienceName = experienceName
        self.experienceInstanceID = experienceInstanceID
        self.frameID = update.properties?["frameID"] as? String

        self.stepID = UUID(uuidString: update.properties?["stepId"] as? String ?? "")
        self.stepIndex = Experience.StepIndex(description: update.properties?["stepIndex"] as? String ?? "")

        self.errorID = UUID(uuidString: update.properties?["errorId"] as? String ?? "")
        self.message = update.properties?["message"] as? String
    }

    init(
        type: Events.Experience,
        experienceID: UUID,
        experienceName: String,
        experienceInstanceID: UUID,
        frameID: String? = nil,
        stepID: UUID? = nil,
        stepIndex: Experience.StepIndex? = nil,
        errorID: UUID? = nil,
        message: String? = nil
    ) {
        self.type = type
        self.experienceID = experienceID
        self.experienceName = experienceName
        self.experienceInstanceID = experienceInstanceID
        self.frameID = frameID
        self.stepID = stepID
        self.stepIndex = stepIndex
        self.errorID = errorID
        self.message = message
    }
}

private extension Events.Experience {
    init?(trackingType: TrackingUpdate.TrackingType) {
        if case .event(let name, _) = trackingType, let val = Self(rawValue: name) {
            self = val
        } else {
            return nil
        }
    }
}
