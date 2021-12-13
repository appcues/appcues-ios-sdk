//
//  AnalyticsTracker.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/25/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation
import UIKit

internal class AnalyticsTracker: AnalyticsSubscriber {

    private let container: DIContainer

    private lazy var storage = container.resolve(Storage.self)
    private lazy var config = container.resolve(Appcues.Config.self)
    private lazy var networking = container.resolve(Networking.self)
    private lazy var experienceRenderer = container.resolve(ExperienceRenderer.self)

    init(container: DIContainer) {
        self.container = container
        registerForAnalyticsUpdates(container)
    }

    func track(update: TrackingUpdate) {
        guard let activity = Activity(from: update, config: config, storage: storage),
              let data = try? Networking.encoder.encode(activity) else {
            return
        }

        networking.post(
            to: Networking.APIEndpoint.activity,
            body: data
        ) { [weak self] in
            self?.handleAnalyticsResponse(result: $0)
        }
    }

    private func handleAnalyticsResponse(result: Result<Taco, Error>) {
        switch result {
        case .success(let taco):
            // This prioritizes experiencess over legacy web flows and assumes that the returned flows are ordered by priority.
            if let experience = taco.experiences.first {
                experienceRenderer.show(experience: experience)
            } else if let flow = taco.contents.first {
                experienceRenderer.show(flow: flow)
            }
        case .failure(let error):
            print(error)
        }
    }
}

extension Activity {
    init?(from update: TrackingUpdate, config: Appcues.Config, storage: Storage) {
        switch update.type {
        case let .event(name):
            self.init(accountID: config.accountID,
                      userID: storage.userID,
                      events: [Event(name: name, attributes: update.properties)],
                      groupID: storage.groupID)

        case let .screen(title):
            guard let urlString = generatePseudoURL(screenName: title) else {
                config.logger.error("Could not construct url for page %s", title)
                return nil
            }
            self.init(accountID: config.accountID,
                      userID: storage.userID,
                      events: [Event(pageView: urlString, attributes: update.properties)],
                      groupID: storage.groupID)

        case .profile:
            self.init(accountID: config.accountID,
                      userID: storage.userID,
                      events: nil,
                      profileUpdate: update.properties,
                      groupID: storage.groupID)

        case .group:
            self.init(accountID: config.accountID,
                      userID: storage.userID,
                      events: nil,
                      groupID: storage.groupID,
                      groupUpdate: update.properties)
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
