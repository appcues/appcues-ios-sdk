//
//  AnalyticsTracker.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/25/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation
import UIKit

internal class AnalyticsTracker {

    private let container: DIContainer

    private lazy var config = container.resolve(Appcues.Config.self)
    private lazy var networking = container.resolve(Networking.self)
    private lazy var experienceRenderer = container.resolve(ExperienceRenderer.self)

    init(container: DIContainer) {
        self.container = container
        registerForAnalyticsUpdates(container)
    }

    private func identify(userID: String, properties: [String: Any]? = nil) {
        let activity = Activity(accountID: config.accountID, userID: userID, events: nil, profileUpdate: properties)
        guard let data = try? Networking.encoder.encode(activity) else {
            return
        }

        networking.post(
            to: Networking.APIEndpoint.activity,
            body: data
        ) { (result: Result<Taco, Error>) in
            print(result)
        }
    }

    private func track(userID: String, name: String, properties: [String: Any]? = nil) {
        let activity = Activity(accountID: config.accountID, userID: userID, events: [Event(name: name, attributes: properties)])
        guard let data = try? Networking.encoder.encode(activity) else {
            return
        }

        networking.post(
            to: Networking.APIEndpoint.activity,
            body: data
        ) { (result: Result<Taco, Error>) in
            print(result)
        }
    }

    private func screen(userID: String, title: String, properties: [String: Any]? = nil) {
        guard let urlString = generatePseudoURL(screenName: title) else {
            config.logger.error("Could not construct url for page %s", title)
            return
        }

        let activity = Activity(accountID: config.accountID, userID: userID, events: [Event(pageView: urlString, attributes: properties)])
        guard let data = try? Networking.encoder.encode(activity) else {
            return
        }

        networking.post(
            to: Networking.APIEndpoint.activity,
            body: data
        ) { [weak self] (result: Result<Taco, Error>) in
            switch result {
            case .success(let taco):
                // This assumes that the returned flows are ordered by priority.
                if let flow = taco.contents.first {
                    self?.experienceRenderer.show(flow: flow)
                }
            case .failure(let error):
                print(error)
            }
        }
    }

    // Temporary solution to piggyback on the web page views. A proper mobile screen solution is still needed.
    private func generatePseudoURL(screenName: String) -> String? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = Bundle.main.bundleIdentifier
        components.path = "/" + screenName.asURLSlug
        return components.string
    }
}

extension AnalyticsTracker: AnalyticsSubscriber {
    func track(update: TrackingUpdate) {
        switch update.type {
        case let .event(name):
            track(userID: update.userID, name: name, properties: update.properties)

        case let .screen(title):
            screen(userID: update.userID, title: title, properties: update.properties)

        case .profile:
            identify(userID: update.userID, properties: update.properties)
        }
    }
}
