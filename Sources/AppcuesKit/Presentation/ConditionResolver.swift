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
    func resolve<T>(conditionals: [Conditional<T>]) -> T?
}

@available(iOS 13.0, *)
internal class ConditionResolver: ConditionResolving, AnalyticsSubscribing {

    private var latestProperties: [String: Any] = [:]

    let autoPropertyDecorator: AutoPropertyDecorator

    init(container: DIContainer) {
        self.autoPropertyDecorator = container.resolve(AutoPropertyDecorator.self)
    }

    func resolve<T>(conditionals: [Conditional<T>]) -> T? where T: Decodable {
        let state = Condition.State(properties: latestProperties)

        return conditionals.first { $0.conditions.evaluate(state: state) }?.data
    }

    // MARK: - AnalyticsSubscribing
    func track(update: TrackingUpdate) {
        if case .profile = update.type {
            latestProperties = update.properties ?? latestProperties
        }
    }
}
