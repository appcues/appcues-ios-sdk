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
    let config: Appcues.Config

    private lazy var storage = container.resolve(DataStoring.self)
    private lazy var uiDebugger = container.resolve(UIDebugging.self)
    private lazy var traitRegistry = container.resolve(TraitRegistry.self)
    private lazy var actionRegistry = container.resolve(ActionRegistry.self)
    private lazy var sessionMonitor = container.resolve(SessionMonitoring.self)
    private lazy var experienceLoader = container.resolve(ExperienceLoading.self)
    private lazy var notificationCenter = container.resolve(NotificationCenter.self)

    private var subscribers: [AnalyticsSubscribing] = []
    private var decorators: [AnalyticsDecorating] = []

    /// The delegate object that manages and observes experience presentations.
    public weak var delegate: AppcuesExperienceDelegate?

    /// Creates an instance of Appcues analytics.
    /// - Parameter config: `Config` object for this instance.
    public init(config: Config) {
        self.config = config

        initializeContainer()
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

    /// Identify a group for the current user
    /// - Parameters:
    ///   - groupID: Unique value identifying the group.
    ///   - properties: Optional properties that provide additional context about the group.
    public func group(groupID: String?, properties: [String: Any]? = nil) {
        var groupID = groupID
        var properties = properties

        // any empty string is interpreted as clearing the group, same as nil
        if let strongID = groupID, strongID.isEmpty {
            groupID = nil
        }

        // when clearing the group, ensure no properties are sent - invalid
        if groupID == nil {
            properties = nil
        }

        storage.groupID = groupID
        publish(TrackingUpdate(type: .group, properties: properties))
    }

    /// Generate a unique ID for the current user when there is not a known identity to use in
    /// the `identify` call.  This will cause the SDK to begin tracking activity and checking for
    /// qualified content.
    public func anonymous(properties: [String: Any]? = nil) {
        identify(isAnonymous: true, userID: config.anonymousIDFactory(), properties: properties)
    }

    /// Clears out the current user in this session.  Can be used when the user logs out of your application.
    public func reset() {
        // call this first to close final analytics on the session
        sessionMonitor.reset()

        storage.userID = ""
        storage.isAnonymous = true
        storage.groupID = nil
        notificationCenter.post(name: .appcuesReset, object: self, userInfo: nil)
    }

    /// Track an action taken by a user.
    /// - Parameters:
    ///   - name: Name of the event.
    ///   - properties: Optional properties that provide additional context about the event.
    public func track(name: String, properties: [String: Any]? = nil) {
        track(name: name, properties: properties, sync: true)
    }

    /// Track an screen viewed by a user.
    /// - Parameters:
    ///   - title: Name of the screen.
    ///   - properties: Optional properties that provide additional context about the event.
    public func screen(title: String, properties: [String: Any]? = nil) {
        publish(TrackingUpdate(type: .screen(title), properties: properties))
    }

    /// Forces specific Appcues experience to appear for the current user by passing in the ID.
    /// - Parameters:
    ///   - experienceID: ID of the experience.
    ///
    /// This method ignores any targeting that is set on the flow or checklist.
    public func show(experienceID: String) {
        guard sessionMonitor.isActive else { return }
        experienceLoader.load(experienceID: experienceID, published: true)
    }

    /// Register a trait that modifies an `Experience`.
    /// - Parameter trait: Trait to register.
    public func register(trait: ExperienceTrait.Type) {
        traitRegistry.register(trait: trait)
    }

    /// Register an action that can be activated in an `Experience`.
    /// - Parameter action: Action to register.
    public func register(action: ExperienceAction.Type) {
        actionRegistry.register(action: action)
    }

    /// Launches the Appcues debugger over your app's UI.
    public func debug() {
        uiDebugger.show()
    }

    /// Enables automatic screen tracking.
    public func trackScreens() {
        // resolving will init UIKitScreenTracking, which sets up the swizzling of
        // UIViewController for automatic screen tracking
        _ = container.resolve(UIKitScreenTracker.self)
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
    public func didHandleURL(_ url: URL) -> Bool {
        return container.resolve(DeeplinkHandling.self).didHandleURL(url)
    }

    func initializeContainer() {
        container.register(Appcues.self, value: self)
        container.register(Config.self, value: config)
        container.register(AnalyticsPublishing.self, value: self)
        container.registerLazy(DataStoring.self, initializer: Storage.init)
        container.registerLazy(Networking.self, initializer: NetworkClient.init)
        container.registerLazy(ExperienceLoading.self, initializer: ExperienceLoader.init)
        container.registerLazy(ExperienceRendering.self, initializer: ExperienceRenderer.init)
        container.registerLazy(UIDebugging.self, initializer: UIDebugger.init)
        container.registerLazy(DeeplinkHandling.self, initializer: DeeplinkHandler.init)
        container.registerLazy(AnalyticsTracking.self, initializer: AnalyticsTracker.init)
        container.registerLazy(SessionMonitoring.self, initializer: SessionMonitor.init)
        container.registerLazy(UIKitScreenTracker.self, initializer: UIKitScreenTracker.init)
        container.registerLazy(AutoPropertyDecorator.self, initializer: AutoPropertyDecorator.init)
        container.registerLazy(TraitRegistry.self, initializer: TraitRegistry.init)
        container.registerLazy(ActionRegistry.self, initializer: ActionRegistry.init)
        container.registerLazy(NotificationCenter.self, initializer: NotificationCenter.init)
        container.registerLazy(ActivityProcessing.self, initializer: ActivityProcessor.init)

        // anything that should happen at startup automatically is handled here

        // register core analytics tracking to receive tracking updates
        if let trackingSubscriber = container.resolve(AnalyticsTracking.self) as? AnalyticsSubscribing {
            register(subscriber: trackingSubscriber)
        }

        // register the autoproperty decorator
        let autoPropDecorator = container.resolve(AutoPropertyDecorator.self)
        register(decorator: autoPropDecorator)

        // start session monitoring
        sessionMonitor.start()
    }

    private func identify(isAnonymous: Bool, userID: String, properties: [String: Any]? = nil) {
        guard !userID.isEmpty else {
            config.logger.error("Invalid userID - empty string")
            return
        }

        let userChanged = userID != storage.userID
        storage.userID = userID
        storage.isAnonymous = isAnonymous
        if userChanged {
            // when the idenfied use changes from last known value, we must start a new session
            sessionMonitor.start()

            // and clear any stored group information - will have to be reset as needed
            storage.groupID = nil
        }
        publish(TrackingUpdate(type: .profile, properties: properties))
    }
}

extension Appcues: AnalyticsPublishing {
    func track(name: String, properties: [String: Any]?, sync: Bool) {
        publish(TrackingUpdate(type: .event(name: name, sync: sync), properties: properties))
    }

    func register(subscriber: AnalyticsSubscribing) {
        subscribers.append(subscriber)
    }

    func remove(subscriber: AnalyticsSubscribing) {
        subscribers.removeAll { $0 === subscriber }
    }

    func register(decorator: AnalyticsDecorating) {
        decorators.append(decorator)
    }

    func remove(decorator: AnalyticsDecorating) {
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
        guard sessionMonitor.isActive else { return }

        var update = update

        for decorator in decorators {
            update = decorator.decorate(update)
        }

        for subscriber in subscribers {
            subscriber.track(update: update)
        }
    }
}

extension Notification.Name {
    internal static let appcuesReset = Notification.Name("appcuesReset")
}
