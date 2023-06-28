//
//  ConditionResolver.swift
//  AppcuesKit
//
//  Created by Matt on 2023-06-28.
//  Copyright © 2023 Appcues. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
internal protocol ConditionResolving: AnyObject {
    func resolve<T>(conditionals: [Conditional<T>], stepState: ExperienceData.StepState?) -> T?

}

@available(iOS 13.0, *)
extension ConditionResolving {
    func resolve<T>(conditionals: [Conditional<T>]) -> T? {
        return resolve(conditionals: conditionals, stepState: nil)
    }
}

@available(iOS 13.0, *)
internal class ConditionResolver: ConditionResolving, AnalyticsSubscribing {

    private var latestProperties: [String: Any] = [:]

    init(container: DIContainer) {
    }

    func resolve<T>(conditionals: [Conditional<T>], stepState: ExperienceData.StepState?) -> T? where T: Decodable {
        let formValues = stepState?.formItems.mapValues { $0.getValue() }
        let state = Condition.State(properties: latestProperties, formValues: formValues)

        return conditionals.first { $0.conditions.evaluate(state: state) }?.data
    }

    // MARK: - AnalyticsSubscribing
    func track(update: TrackingUpdate) {
        if case .profile = update.type {
            latestProperties = update.properties ?? latestProperties
        }
    }
}
