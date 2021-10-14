//
//  AppcuesDestination.swift
//  SegmentDestinationExample
//
//  Created by James Ellis on 10/13/21.
//

import Foundation
import Segment
import Appcues

private struct AppcuesSettings: Codable {
    let appcuesId: String
}

/// An implementation of the Appcues device mode destination as a plugin.
public class AppcuesDestination: DestinationPlugin {
    public let timeline = Timeline()
    public let key = "Appcues"
    public let type = PluginType.destination
    public var analytics: Analytics?

    public private(set) var appcues: Appcues?

    public func update(settings: Settings, type: UpdateType) {
        // we've already set up this singleton SDK, can't do it again, so skip.
        guard type == .initial,
              let appcuesSettings: AppcuesSettings = settings.integrationSettings(forPlugin: self) else {
                  return
              }

        appcues = Appcues(config: Config(accountID: appcuesSettings.appcuesId))
    }

    public func identify(event: IdentifyEvent) -> IdentifyEvent? {
        guard let appcues = appcues,
              let userId = event.userId else {
                  return event
              }

        appcues.identify(userID: userId, properties: sanitize(properties: event.traits))
        return event
    }

    public func track(event: TrackEvent) -> TrackEvent? {
        appcues?.track(event: event.event, properties: sanitize(properties: event.properties))
        return event
    }

    public func screen(event: ScreenEvent) -> ScreenEvent? {
        guard let appcues = appcues,
              let title = event.name else {
                  return event
              }

        appcues.screen(title: title, properties: sanitize(properties: event.properties))
        return event
    }

    // We need to build support for [String: Any] properties, converting to strings for now.
    // Also note: https://docs.appcues.com/article/161-javascript-api
    //   Property values can be strings, numbers, or booleans. Beware!
    //   Any identify call with an array or nested object as a property
    //   value will not appear in your Appcues account.
    private func sanitize(properties: JSON?) -> [String: String]? {
        guard let properties = properties?.dictionaryValue else { return nil }
        var sanitized: [String: String] = [:]
        for (key, value) in properties {
            sanitized[key] = "\(value)"
        }
        return sanitized
    }
}
