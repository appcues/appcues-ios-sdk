//
//  Appcues.swift
//  Appcues
//
//  Created by Matt on 2021-10-06.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

/// An object that manages Appcues tracking for your app.
public class Appcues {

    internal let config: Config

    private lazy var currentUserID: String = config.anonymousIDFactory()

    lazy var networking = Networking(config: config)

    /// Temporary internal log of API calls
    var log: [String] = []

    /// Creates an instance of Appcues analytics.
    /// - Parameter config: `Config` object for this instance.
    public init(config: Config) {
        self.config = config
    }

    /// Identify the user and determine if they should see Appcues content.
    /// - Parameters:
    ///   - userID: Unique value identifying the user.
    ///   - properties: Optional properties that provide additional context about the user.
    public func identify(userID: String, properties: [String: String]? = nil) {
        currentUserID = userID

        let activity = Activity(events: nil, profileUpdate: properties)
        guard let data = try? Networking.encoder.encode(activity) else {
            return
        }

        networking.post(
            to: .activity(accountID: config.accountID, userID: userID),
            body: data
        ) { (result: Result<Taco, Error>) in
            print(result)
        }

        log.append("Appcues.identify(userID: \(userID))")
    }

    /// Track an action taken by a user.
    /// - Parameters:
    ///   - event: Name of the event.
    ///   - properties: Optional properties that provide additional context about the event.
    public func track(event: String, properties: [String: String]? = nil) {
        let activity = Activity(events: [Event(name: event, attributes: properties)], profileUpdate: nil)
        guard let data = try? Networking.encoder.encode(activity) else {
            return
        }

        networking.post(
            to: .activity(accountID: config.accountID, userID: currentUserID),
            body: data
        ) { (result: Result<Taco, Error>) in
            print(result)
        }

        log.append("Appcues.track(event: \(event))")
    }

    /// Track an screen viewed by a user.
    /// - Parameters:
    ///   - title: Name of the screen.
    ///   - properties: Optional properties that provide additional context about the event.
    public func screen(title: String, properties: [String: String]? = nil) {
        guard let urlString = generatePseudoURL(screenName: title) else {
            config.logger.error("Could not construct url for page %s", title)
            return
        }

        let activity = Activity(events: [Event(pageView: urlString, attributes: properties)])
        guard let data = try? Networking.encoder.encode(activity) else {
            return
        }

        networking.post(
            to: .activity(accountID: config.accountID, userID: currentUserID),
            body: data
        ) { (result: Result<Taco, Error>) in
            print(result)
        }

        log.append("Appcues.screen(title: \(title))")
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
