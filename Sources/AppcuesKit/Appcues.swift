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

    let config: Config
    let storage: Storage
    let networking: Networking
    let flowRenderer: FlowRenderer
    let analyticsTracker: AnalyticsTracker
    let styleLoader: StyleLoader
    let uiDebugger: UIDebugger

    /// Creates an instance of Appcues analytics.
    /// - Parameter config: `Config` object for this instance.
    public init(config: Config) {
        self.config = config
        self.storage = Storage(config: config)
        self.networking = Networking(config: config)
        self.uiDebugger = UIDebugger(config: config)
        self.styleLoader = StyleLoader(networking: networking)
        self.flowRenderer = FlowRenderer(config: config, networking: networking, storage: storage, styleLoader: styleLoader)
        self.analyticsTracker = AnalyticsTracker(config: config, storage: storage, networking: networking)

        self.analyticsTracker.flowQualified = { self.flowRenderer.show(flow: $0) }

        if storage.launchType == .install {
            // perform any fresh install activities here
            storage.userID = config.anonymousIDFactory()
        }
    }

    /// Identify the user and determine if they should see Appcues content.
    /// - Parameters:
    ///   - userID: Unique value identifying the user.
    ///   - properties: Optional properties that provide additional context about the user.
    public func identify(userID: String, properties: [String: Any]? = nil) {
        storage.userID = userID
        analyticsTracker.identify(properties: properties)
    }

    /// Track an action taken by a user.
    /// - Parameters:
    ///   - name: Name of the event.
    ///   - properties: Optional properties that provide additional context about the event.
    public func track(name: String, properties: [String: Any]? = nil) {
        analyticsTracker.track(name: name, properties: properties)
    }

    /// Track an screen viewed by a user.
    /// - Parameters:
    ///   - title: Name of the screen.
    ///   - properties: Optional properties that provide additional context about the event.
    public func screen(title: String, properties: [String: Any]? = nil) {
        analyticsTracker.screen(title: title, properties: properties)
    }

    /// Forces specific Appcues content to appear for the current user by passing in the ID.
    /// - Parameters:
    ///   - contentID: ID of the flow.
    ///
    /// This method ignores any targeting that is set on the flow or checklist.
    public func show(contentID: String) {
        flowRenderer.show(contentID: contentID)
    }

    /// Launches the Appcues debugger over your app's UI.
    public func debug() {
        uiDebugger.show()
    }
}
