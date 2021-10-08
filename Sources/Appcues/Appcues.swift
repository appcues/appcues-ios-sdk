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

    /// Temporary internal log of API calls
    var log: [String] = []

    /// Creates an instance of Appcues analytics.
    public init() {
    }

    /// Identify the user and determine if they should see Appcues content.
    /// - Parameters:
    ///   - userId: Unique value identifying the user.
    ///   - traits: Optional properties that provide additional context about the user.
    public func identify(userId: String, traits: [String: String]) {
        log.append("Appcues.identify(userId: \(userId))")
    }

    /// Track an action taken by a user.
    /// - Parameters:
    ///   - event: Name of the event.
    ///   - properties: Optional properties that provide additional context about the event.
    public func track(event: String, properties: [String: String]) {
        log.append("Appcues.track(event: \(event))")
    }

    /// Track an screen viewed by a user.
    /// - Parameters:
    ///   - title: Name of the screen.
    ///   - properties: Optional properties that provide additional context about the event.
    public func screen(title: String, properties: [String: String]) {
        log.append("Appcues.screen(title: \(title))")
    }
}
