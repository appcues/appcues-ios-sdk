//
//  Appcues.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-06.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

/// An object that manages Appcues tracking for your app.
@objc(Appcues)
public class Appcues: NSObject {

    let container = DIContainer()
    let config: Appcues.Config

    private lazy var analyticsPublisher = container.resolve(AnalyticsPublishing.self)
    private lazy var storage = container.resolve(DataStoring.self)
    private lazy var sessionMonitor = container.resolve(SessionMonitoring.self)

    private var _uiDebugger: Any?
    @available(iOS 13.0, *)
    private var uiDebugger: UIDebugging {
        if _uiDebugger == nil {
            _uiDebugger = container.resolve(UIDebugging.self)
        }
        // swiftlint:disable:next force_cast
        return _uiDebugger as! UIDebugging
    }

    private var _traitRegistry: Any?
    @available(iOS 13.0, *)
    private var traitRegistry: TraitRegistry {
        if _traitRegistry == nil {
            _traitRegistry = container.resolve(TraitRegistry.self)
        }
        // swiftlint:disable:next force_cast
        return _traitRegistry as! TraitRegistry
    }

    private var _actionRegistry: Any?
    @available(iOS 13.0, *)
    private var actionRegistry: ActionRegistry {
        if _actionRegistry == nil {
            _actionRegistry = container.resolve(ActionRegistry.self)
        }
        // swiftlint:disable:next force_cast
        return _actionRegistry as! ActionRegistry
    }

    private var _experienceLoader: Any?
    @available(iOS 13.0, *)
    private var experienceLoader: ExperienceLoading {
        if _experienceLoader == nil {
            _experienceLoader = container.resolve(ExperienceLoading.self)
        }
        // swiftlint:disable:next force_cast
        return _experienceLoader as! ExperienceLoading
    }

    private lazy var notificationCenter = container.resolve(NotificationCenter.self)

    /// The delegate object that manages and observes experience presentations.
    @objc public weak var experienceDelegate: AppcuesExperienceDelegate?

    /// The delegate object that observes published analytics events
    @objc public weak var analyticsDelegate: AppcuesAnalyticsDelegate?

    var sessionID: UUID?
    var isActive: Bool { sessionID != nil }

    /// Creates an instance of Appcues analytics.
    /// - Parameter config: `Config` object for this instance.
    @objc
    public init(config: Config) {
        self.config = config

        super.init()

        initializeContainer()

        config.logger.info("Appcues SDK %{public}s initialized", version())
    }

    /// Get the current version of the Appcues SDK.
    /// - Returns: Current version of the Appcues SDK.
    @objc(sdkVersion)
    public static func version() -> String {
        return __appcues_version
    }

    /// Get the current version of the Appcues SDK.
    /// - Returns: Current version of the Appcues SDK.
    @objc
    public func version() -> String {
        return Appcues.version()
    }

    /// Identify the user and determine if they should see Appcues content.
    /// - Parameters:
    ///   - userID: Unique value identifying the user.
    ///   - properties: Optional properties that provide additional context about the user.
    @objc
    public func identify(userID: String, properties: [String: Any]? = nil) {
        identify(isAnonymous: false, userID: userID, properties: properties)
    }

    /// Identify a group for the current user.
    /// - Parameters:
    ///   - groupID: Unique value identifying the group.
    ///   - properties: Optional properties that provide additional context about the group.
    @objc
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
        analyticsPublisher.publish(TrackingUpdate(type: .group(groupID), properties: properties, isInternal: false))
    }

    /// Generate a unique ID for the current user when there is not a known identity to use in
    /// the `identify` call.  This will cause the SDK to begin tracking activity and checking for
    /// qualified content.
    @objc
    public func anonymous(properties: [String: Any]? = nil) {
        identify(isAnonymous: true, userID: config.anonymousIDFactory(), properties: properties)
    }

    /// Clears out the current user in this session.  Can be used when the user logs out of your application.
    @objc
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
    @objc
    public func track(name: String, properties: [String: Any]? = nil) {
        analyticsPublisher.publish(TrackingUpdate(type: .event(name: name, interactive: true), properties: properties, isInternal: false))

    }

    /// Track an screen viewed by a user.
    /// - Parameters:
    ///   - title: Name of the screen.
    ///   - properties: Optional properties that provide additional context about the event.
    @objc
    public func screen(title: String, properties: [String: Any]? = nil) {
        analyticsPublisher.publish(TrackingUpdate(type: .screen(title), properties: properties, isInternal: false))
    }

    /// Forces specific Appcues experience to appear for the current user by passing in the ID.
    /// - Parameters:
    ///   - experienceID: ID of the experience.
    ///   - completion: The block to execute after the attempt to show the content has completed.
    ///   This block has a `Bool` parameter which indicates if the attempt to show the content succeeded.
    ///   If it was not successful, a non-nil `Error` parameter will also be included.
    ///
    /// This method ignores any targeting that is set on the flow or checklist.
    @objc
    public func show(experienceID: String, completion: ((Bool, Error?) -> Void)? = nil) {
        guard #available(iOS 13.0, *) else {
            config.logger.error("iOS 13 or above is required to show an Appcues experience")
            completion?(false, AppcuesError.unsupportedOSVersion)
            return
        }

        guard isActive else {
            config.logger.error("An active Appcues session is required to show an Appcues experience")
            completion?(false, AppcuesError.noActiveSession)
            return
        }

        experienceLoader.load(experienceID: experienceID, published: true) { result in
            switch result {
            case .success:
                completion?(true, nil)
            case .failure(let error):
                completion?(false, error)
            }
        }
    }

    /// Register a trait that modifies an `Experience`.
    /// - Parameter trait: Trait to register.
    @objc
    public func register(trait: ExperienceTrait.Type) {
        guard #available(iOS 13.0, *) else { return }

        traitRegistry.register(trait: trait)
    }

    /// Register an action that can be activated in an `Experience`.
    /// - Parameter action: Action to register.
    @objc
    public func register(action: ExperienceAction.Type) {
        guard #available(iOS 13.0, *) else { return }

        actionRegistry.register(action: action)
    }

    /// Launches the Appcues debugger over your app's UI.
    ///
    /// See <doc:Debugging> for usage information.
    @objc
    public func debug() {
        guard #available(iOS 13.0, *) else {
            config.logger.error("iOS 13 or above is required to use the Appcues inline debugger")
            return
        }

        uiDebugger.show(destination: nil)
    }

    /// Enables automatic screen tracking.
    @objc
    public func trackScreens() {
        // resolving will init UIKitScreenTracking, which sets up the swizzling of
        // UIViewController for automatic screen tracking
        _ = container.resolve(UIKitScreenTracker.self)
    }

    /// Verifies if an incoming URL is intended for the Appcues SDK.
    /// - Parameter url: The URL being opened.
    /// - Returns: `true` if the URL matches the Appcues URL Scheme or `false` if the URL is not known by the Appcues SDK.
    ///
    /// If the `url` is an Appcues URL, this function may launch an experience or otherwise alter the UI state.
    ///
    /// This function is intended to be called added at the top of your `UIApplicationDelegate`'s `application(_:open:options:)` function:
    /// ```swift
    /// guard !<#appcuesInstance#>.didHandleURL(url) else { return true }
    /// ```
    @discardableResult
    @objc
    public func didHandleURL(_ url: URL) -> Bool {
        guard #available(iOS 13.0, *) else { return false }

        return container.resolve(DeepLinkHandling.self).didHandleURL(url)
    }

    func initializeContainer() {
        container.owner = self
        container.register(Config.self, value: config)
        container.registerLazy(AnalyticsPublishing.self, initializer: AnalyticsPublisher.init)
        container.registerLazy(DataStoring.self, initializer: Storage.init)
        container.registerLazy(Networking.self, initializer: NetworkClient.init)
        container.registerLazy(AnalyticsTracking.self, initializer: AnalyticsTracker.init)
        container.registerLazy(SessionMonitoring.self, initializer: SessionMonitor.init)
        container.registerLazy(UIKitScreenTracker.self, initializer: UIKitScreenTracker.init)
        container.registerLazy(AutoPropertyDecorator.self, initializer: AutoPropertyDecorator.init)
        container.registerLazy(NotificationCenter.self, initializer: NotificationCenter.init)
        container.registerLazy(ActivityProcessing.self, initializer: ActivityProcessor.init)
        container.registerLazy(ActivityStoring.self, initializer: ActivityFileStorage.init)
        container.registerLazy(AnalyticsBroadcaster.self, initializer: AnalyticsBroadcaster.init)

        if #available(iOS 13.0, *) {
            container.registerLazy(DeepLinkHandling.self, initializer: DeepLinkHandler.init)
            container.registerLazy(UIDebugging.self, initializer: UIDebugger.init)
            container.registerLazy(ExperienceLoading.self, initializer: ExperienceLoader.init)
            container.registerLazy(ExperienceRendering.self, initializer: ExperienceRenderer.init)
            container.registerLazy(TraitRegistry.self, initializer: TraitRegistry.init)
            container.registerLazy(ActionRegistry.self, initializer: ActionRegistry.init)
            container.registerLazy(TraitComposing.self, initializer: TraitComposer.init)
        }

        // anything that should happen at startup automatically is handled here

        // register core analytics tracking to receive tracking updates
        if let trackingSubscriber = container.resolve(AnalyticsTracking.self) as? AnalyticsSubscribing {
            analyticsPublisher.register(subscriber: trackingSubscriber)
        }

        // register the analytics broadcaster to notify optional analyticsDelegate of tracking data
        let analyticsBroadcaster = container.resolve(AnalyticsBroadcaster.self)
        analyticsPublisher.register(subscriber: analyticsBroadcaster)

        // register the autoproperty decorator
        let autoPropDecorator = container.resolve(AutoPropertyDecorator.self)
        analyticsPublisher.register(decorator: autoPropDecorator)

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
            // when the identified user changes from last known value, we must start a new session
            sessionMonitor.start()

            // and clear any stored group information - will have to be reset as needed
            storage.groupID = nil
        }
        analyticsPublisher.publish(TrackingUpdate(type: .profile, properties: properties, isInternal: false))
    }
}

extension Notification.Name {
    internal static let appcuesReset = Notification.Name("appcuesReset")
}
