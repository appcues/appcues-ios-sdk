//
//  Appcues.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-06.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation
import UIKit

/// An object that manages Appcues tracking for your app.
public class Appcues {

    let container = DIContainer()

    private let config: Appcues.Config
    private lazy var storage = container.resolve(Storage.self)
    private lazy var uiDebugger = container.resolve(UIDebugger.self)
    private lazy var traitRegistry = container.resolve(TraitRegistry.self)
    private lazy var actionRegistry = container.resolve(ActionRegistry.self)
    private lazy var experienceLoader = container.resolve(ExperienceLoader.self)

    private var subscribers: [AnalyticsSubscriber] = []
    private var decorators: [TrackingDecorator] = []

    // controls whether the SDK is actively tracking data - which means we either
    // have an identified user, or were explicitly asked to track an anonymous user
    var isActive = false

    /// Creates an instance of Appcues analytics.
    /// - Parameter config: `Config` object for this instance.
    public init(config: Config) {
        self.config = config
        initializeContainer()
        initializeSession()
    }

    /// Get the current version of the Appcues SDK.
    /// - Returns: Current version of the Appcues SDK.
    public static func version() -> String {
        return __appcues_version
    }

    /// Get the current version of the Appcues SDK.
    /// - Returns: Current version of the Appcues SDK.
    public func version() -> String {
        return Appcues.version()
    }

    /// Identify the user and determine if they should see Appcues content.
    /// - Parameters:
    ///   - userID: Unique value identifying the user.
    ///   - properties: Optional properties that provide additional context about the user.
    public func identify(userID: String, properties: [String: Any]? = nil) {
        identify(isAnonymous: false, userID: userID, properties: properties)
    }

    /// Generate a unique ID for the current user when there is not a known identity to use in
    /// the `identify` call.  This will cause the SDK to begin tracking activity and checking for
    /// qualified content.
    public func anonymous(properties: [String: Any]? = nil) {
        identify(isAnonymous: true, userID: config.anonymousIDFactory(), properties: properties)
    }

    /// Clears out the current user in this session.  Can be used when the user logs out of your application.
    public func reset() {
        isActive = false
        storage.userID = ""
        storage.isAnonymous = true
    }

    /// Track an action taken by a user.
    /// - Parameters:
    ///   - name: Name of the event.
    ///   - properties: Optional properties that provide additional context about the event.
    public func track(name: String, properties: [String: Any]? = nil) {
        publish(TrackingUpdate(type: .event(name), properties: properties, userID: storage.userID))
    }

    /// Track an screen viewed by a user.
    /// - Parameters:
    ///   - title: Name of the screen.
    ///   - properties: Optional properties that provide additional context about the event.
    public func screen(title: String, properties: [String: Any]? = nil) {
        publish(TrackingUpdate(type: .screen(title), properties: properties, userID: storage.userID))
    }

    /// Forces specific Appcues content to appear for the current user by passing in the ID.
    /// - Parameters:
    ///   - contentID: ID of the flow.
    ///
    /// This method ignores any targeting that is set on the flow or checklist.
    public func show(contentID: String) {
        guard isActive else { return }
        experienceLoader.load(contentID: contentID)
    }

    /// Register a trait that modifies an `Experience`.
    /// - Parameter trait: Trait to register.
    public func register(trait: ExperienceTrait.Type) {
        traitRegistry.register(trait: trait)
    }

    /// Register an action that can be activated in an `Experience`.
    /// - Parameter trait: Trait to register.
    public func register(action: ExperienceAction.Type) {
        actionRegistry.register(action: action)
    }

    /// Launches the Appcues debugger over your app's UI.
    public func debug() {
        uiDebugger.show()
    }

    /// Verifies if an incoming URL is intended for the Appcues SDK.
    /// - Parameter url: The URL being opened.
    /// - Returns: `true` if the URL matches the Appcues URL Scheme or `false` if the URL is not known by the Appcues SDK.
    ///
    /// If the `url` is an Appcues URL, this function may launch a flow preview or otherwise alter the UI state.
    ///
    /// This function is intended to be called added at the top of your `UIApplicationDelegate`'s `application(_:open:options:)` function:
    /// ```swift
    /// guard !<#appcuesInstance#>.didHandleURL(url) else { return true }
    /// ```
    @discardableResult
    func didHandleURL(_ url: URL) -> Bool {
        return container.resolve(DeeplinkHandler.self).didHandleURL(url)
    }

    private func initializeContainer() {
        container.register(Appcues.self, value: self)
        container.register(Config.self, value: config)
        container.register(AnalyticsPublisher.self, value: self)
        container.registerLazy(Storage.self, initializer: Storage.init)
        container.registerLazy(Networking.self, initializer: Networking.init)
        container.registerLazy(StyleLoader.self, initializer: StyleLoader.init)
        container.registerLazy(ExperienceLoader.self, initializer: ExperienceLoader.init)
        container.registerLazy(ExperienceRenderer.self, initializer: ExperienceRenderer.init)
        container.registerLazy(UIDebugger.self, initializer: UIDebugger.init)
        container.registerLazy(DeeplinkHandler.self, initializer: DeeplinkHandler.init)
        container.registerLazy(AnalyticsTracker.self, initializer: AnalyticsTracker.init)
        container.registerLazy(LifecycleTracking.self, initializer: LifecycleTracking.init)
        container.registerLazy(UIKitScreenTracking.self, initializer: UIKitScreenTracking.init)
        container.registerLazy(AutoPropertyDecorator.self, initializer: AutoPropertyDecorator.init)
        container.registerLazy(TraitRegistry.self, initializer: TraitRegistry.init)
        container.registerLazy(ActionRegistry.self, initializer: ActionRegistry.init)
    }

    private func initializeSession() {
        isActive = !storage.userID.isEmpty

        let previousBuild = storage.applicationBuild
        let currentBuild = Bundle.main.build

        storage.applicationBuild = currentBuild
        storage.applicationVersion = Bundle.main.version

        var launchType = LaunchType.open
        if previousBuild.isEmpty {
            launchType = .install
        } else if previousBuild != currentBuild {
            launchType = .update
        }

        if launchType == .install {
            // perform any fresh install activities here
            storage.deviceID = UIDevice.identifier
        }

        // anything that should be eager init at launch is handled here
        _ = container.resolve(AnalyticsTracker.self)
        _ = container.resolve(AutoPropertyDecorator.self)

        if config.trackLifecycle {
            container.resolve(LifecycleTracking.self).launchType = launchType
        }

        if config.trackScreens {
            _ = container.resolve(UIKitScreenTracking.self)
        }
    }

    private func identify(isAnonymous: Bool, userID: String, properties: [String: Any]? = nil) {
        storage.userID = userID
        storage.isAnonymous = isAnonymous
        isActive = true
        publish(TrackingUpdate(type: .profile, properties: properties, userID: userID))
    }
}

extension Appcues: AnalyticsPublisher {
    func register(subscriber: AnalyticsSubscriber) {
        subscribers.append(subscriber)
    }

    func remove(subscriber: AnalyticsSubscriber) {
        subscribers.removeAll { $0 === subscriber }
    }

    func register(decorator: TrackingDecorator) {
        decorators.append(decorator)
    }

    func remove(decorator: TrackingDecorator) {
        decorators.removeAll { $0 === decorator }
    }

    // for unit testing
    func clearDecorators() {
        decorators.removeAll()
    }

    // for unit testing
    func clearSubscribers() {
        subscribers.removeAll()
    }

    private func publish(_ update: TrackingUpdate) {
        guard isActive else { return }

        var update = update

        for decorator in decorators {
            update = decorator.decorate(update)
        }

        for subscriber in subscribers {
            subscriber.track(update: update)
        }
    }
}
