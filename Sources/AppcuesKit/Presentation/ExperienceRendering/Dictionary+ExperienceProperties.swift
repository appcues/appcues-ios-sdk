//
//  Dictionary+ExperienceProperties.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-19.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

extension Dictionary where Key == String, Value == Any {
    /// Map experience model to a general property dictionary.
    @available(iOS 13.0, *)
    init(
        propertiesFrom experience: ExperienceData,
        stepIndex: Experience.StepIndex? = nil,
        error: Events.Experience.ErrorBody? = nil
    ) {
        var properties: [String: Any] = [
            "experienceId": experience.id.appcuesFormatted,
            "experienceName": experience.name,
            "experienceType": experience.type,
            "experienceInstanceId": experience.instanceID.appcuesFormatted
        ]

        if let localeName = experience.context?.localeName {
            properties["localeName"] = localeName
        }

        if let localeId = experience.context?.localeId {
            properties["localeId"] = localeId
        }

        // frameID is added primarily for use by the debugger
        if case let .embed(frameID) = experience.renderContext {
            properties["frameID"] = frameID
        }

        if let version = experience.publishedAt {
            properties["version"] = version
        }

        if let stepIndex = stepIndex, let step = experience.step(at: stepIndex) {
            properties["stepId"] = step.id.appcuesFormatted
            properties["stepType"] = step.type
            // stepIndex is added primarily for use by the debugger
            properties["stepIndex"] = stepIndex.description
        }

        if let error = error {
            properties["message"] = error.message
            properties["errorId"] = error.id.appcuesFormatted
        }

        self = properties
    }
}

extension Events.Experience {
    struct ErrorBody: ExpressibleByStringInterpolation {
        let message: String?
        let id: UUID

        init(message: String?, id: UUID = UUID.create()) {
            self.message = message
            self.id = id
        }

        // Conveniently init with `"message"` or `"\(messageVar)"` instead of `Events.Experience.ErrorBody(message: messageVar)`.
        init(stringLiteral value: String) {
            message = value
            id = UUID.create()
        }
    }
}
