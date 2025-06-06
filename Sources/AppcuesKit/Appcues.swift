//
//  Appcues.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-06.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation
import UIKit

/// An object that manages Appcues tracking and rendering of experience content, for your app.
@objc(Appcues)
public class Appcues: NSObject {

    /// The element targeting strategy used by the Appcues SDK.
    ///
    /// This strategy controls how the application UI layout hierarchy is captured for building targeted element
    /// experiences. It is also used to control how elements are found for positioning content during rendering of targeted element
    /// experiences, such as anchored tooltips. By default, the SDK uses a strategy for native iOS UIKit applications.
    @available(iOS 13.0, *)
    public static var elementTargeting: AppcuesElementTargeting = UIKitElementTargeting()

    @available(iOS 13.0, *)
    internal static var customComponentRegistry = CustomComponentRegistry()

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

    private var _contentLoader: Any?
    @available(iOS 13.0, *)
    private var contentLoader: ContentLoading {
        if _contentLoader == nil {
            _contentLoader = container.resolve(ContentLoading.self)
        }
        // swiftlint:disable:next force_cast
        return _contentLoader as! ContentLoading
    }

    private lazy var notificationCenter = container.resolve(NotificationCenter.self)

    /// The delegate object that manages and observes experience presentations.
    /// Using ``presentationDelegate`` is preferred because it provides additional context about the experience being  presented.
    @objc public weak var experienceDelegate: AppcuesExperienceDelegate?

    /// The delegate object that manages and observes experience presentations.
    @objc public weak var presentationDelegate: AppcuesPresentationDelegate?

    /// The delegate object that observes published analytics events.
    @objc public weak var analyticsDelegate: AppcuesAnalyticsDelegate?

    /// The delegate object that handles application screen navigation during experience presentation.
    @objc public weak var navigationDelegate: AppcuesNavigationDelegate?

    var sessionID: UUID?
    var isActive: Bool { sessionID != nil }

    /// Creates an instance of Appcues.
    /// - Parameter config: `Config` object for this instance, containing initialization options.
    @objc
    public init(config: Config) {
        self.config = config

        super.init()

        initializeContainer()

        config.logger.info("Appcues SDK %{public}@ initialized", version())
    }

    /// Enables automatic push notification management.
    ///
    /// This should be called in `UIApplicationDelegate.application(_:didFinishLaunchingWithOptions:)`
    /// to ensure no incoming notifications are missed.
    ///
    /// The following will automatically be handled:
    /// 1. Calling `UIApplication.registerForRemoteNotifications()`
    /// 2. Implementing `UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`
    /// to call ``setPushToken(_:)``
    /// 3. Ensuring `UNUserNotificationCenter.current().delegate` is set
    /// 4. Implementing `UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:)`
    /// to call ``didReceiveNotification(response:completionHandler:)``
    /// 5. Implementing `UNUserNotificationCenterDelegate.userNotificationCenter(_:willPresent:withCompletionHandler:)`
    /// to show notification while the app is in the foreground
    @objc
    public static func enableAutomaticPushConfig() {
        PushAutoConfig.configureAutomatically()
    }

    /// Register a view controller that can be rendered in an `Experience`.
    /// - Parameters:
    ///   - identifier: View name
    ///   - type: View controller type
    public static func registerCustomComponent(identifier: String, type: AppcuesCustomComponentViewController.Type) {
        // NOTE: this can't be @objc because the AppcuesCustomComponentView protocol inherits from UIView
        guard #available(iOS 13.0, *) else { return }

        customComponentRegistry.registerCustomComponent(identifier: identifier, type: type)
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
    ///
    /// To authenticate requests for this user, provide the Base64 encoded signature
    /// for this user as a `String` value for key "appcues:user_id_signature", in the `properties` provided.
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
    /// the `identify` call. This will cause the SDK to begin tracking activity and checking for
    /// qualified content.
    @objc
    public func anonymous() {
        identify(isAnonymous: true, userID: "anon:\(config.anonymousIDFactory())", properties: nil)
    }

    /// Clears out the current user in this session. Can be used when the user logs out of your application.
    @objc
    public func reset() {
        analyticsPublisher.publish(TrackingUpdate(
            type: .event(name: Events.Device.deviceUnregistered.rawValue, interactive: false),
            properties: ["reason": "sdk_reset"],
            isInternal: true
        ))

        sessionMonitor.reset()

        storage.userID = ""
        storage.userSignature = nil
        storage.isAnonymous = true
        storage.groupID = nil

        if #available(iOS 13.0, *) {
            let experienceRenderer = container.resolve(ExperienceRendering.self)
            experienceRenderer.resetAll()
        }

        notificationCenter.post(name: .appcuesReset, object: self, userInfo: nil)
    }

    /// Track a custom event for an action taken by a user.
    /// - Parameters:
    ///   - name: Name of the event, cannot be empty.
    ///   - properties: Optional properties that provide additional context about the event.
    @objc
    public func track(name: String, properties: [String: Any]? = nil) {
        guard !name.isEmpty else {
            config.logger.error("Invalid event name - empty string")
            return
        }

        analyticsPublisher.publish(TrackingUpdate(type: .event(name: name, interactive: true), properties: properties, isInternal: false))

    }

    /// Track an screen viewed by a user.
    /// - Parameters:
    ///   - title: Title of the screen.
    ///   - properties: Optional properties that provide additional context about the screen view.
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
    /// This method ignores any targeting that is set on the experience.
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

        contentLoader.load(experienceID: experienceID, published: true, queryItems: [], trigger: .showCall) { result in
            switch result {
            case .success:
                completion?(true, nil)
            case .failure(let error):
                completion?(false, error)
            }
        }
    }

    /// Provide the APNs device token to Appcues.
    ///
    /// - Parameter deviceToken: A globally unique token that identifies this device to APNs.
    ///
    /// This function is intended to be called from  your `UIApplicationDelegate`'s
    /// `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)` function:
    /// ```swift
    /// <#appcuesInstance#>.setPushToken(deviceToken)
    /// ```
    @objc
    public func setPushToken(_ deviceToken: Data?) {
        let pushMonitor = container.resolve(PushMonitoring.self)
        pushMonitor.setPushToken(deviceToken)
    }

    /// Register a trait that modifies an `Experience`.
    /// - Parameter trait: Trait to register.
    /// - Returns: Whether the trait was successfully registered.
    ///
    /// A trait will not be registered if the specified trait type is already registered.
    @objc
    internal func register(trait: AppcuesExperienceTrait.Type) -> Bool {
        guard #available(iOS 13.0, *) else { return false }

        return traitRegistry.register(trait: trait)
    }

    /// Register an action that can be activated in an `Experience`.
    /// - Parameter action: Action to register.
    /// - Returns: Whether the action was successfully registered.
    ///
    /// An action will not be registered if the specified action type is already registered.
    @objc
    internal func register(action: AppcuesExperienceAction.Type) -> Bool {
        guard #available(iOS 13.0, *) else { return false }

        return actionRegistry.register(action: action)
    }

    /// Registers the specified frame to be available to host qualified embedded Appcues experience content.
    /// - Parameters:
    ///   - frameID: The unique identifier for the embedded ``AppcuesFrameView``.
    ///   - view: The ``AppcuesFrameView`` to register for hosting embedded content.
    ///   - parentViewController: The `UIViewController` that owns the provided ``AppcuesFrameView`` instance.
    @objc
    public func register(frameID: String, for view: AppcuesFrameView, on parentViewController: UIViewController) {
        guard #available(iOS 13.0, *) else {
            config.logger.error("iOS 13 or above is required to render embedded experiences")
            return
        }

        view.configure(parentViewController: parentViewController)

        let experienceRenderer = container.resolve(ExperienceRendering.self)
        experienceRenderer.start(owner: view, forContext: .embed(frameID: frameID))
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

        uiDebugger.show(mode: .debugger(nil))
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

    /// Verifies if a user's response to a delivered notification is handled by the Appcues SDK.
    /// - Parameters:
    ///   - response: The user’s response to the notification.
    ///   - completionHandler: The block to execute when you have finished processing the user’s response.
    /// - Returns: `true` if Appcues successfully processed the user's response.
    ///
    /// If the notification is an Appcues push notification, this function may launch an experience or otherwise alter the UI state.
    ///
    /// If `true` is returned, Appcues will execute the `completionHandler` block.
    /// Otherwise you should execute the block when you finish processing the user's response.
    ///
    /// This function is intended to be called added at the top of your
    /// `UNUserNotificationCenterDelegate`'s `userNotificationCenter(_:didReceive:withCompletionHandler:)` function:
    /// ```swift
    /// if <#appcuesInstance#>.didReceiveNotification(response: response, completionHandler: completionHandler) {
    ///     return
    /// }
    /// // App logic here
    /// completionHandler()
    /// ```
    public func didReceiveNotification(response: UNNotificationResponse, completionHandler: @escaping () -> Void) -> Bool {
        return container.resolve(PushMonitoring.self).didReceiveNotification(response: response, completionHandler: completionHandler)
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
        container.registerLazy(PushMonitoring.self, initializer: PushMonitor.init)

        if #available(iOS 13.0, *) {
            container.registerLazy(PushVerifier.self, initializer: PushVerifier.init)
            container.registerLazy(DeepLinkHandling.self, initializer: DeepLinkHandler.init)
            container.registerLazy(UIDebugging.self, initializer: UIDebugger.init)
            container.registerLazy(ContentLoading.self, initializer: ContentLoader.init)
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

        // register the auto property decorator
        let autoPropDecorator = container.resolve(AutoPropertyDecorator.self)
        analyticsPublisher.register(decorator: autoPropDecorator)
    }

    private func identify(isAnonymous: Bool, userID: String, properties: [String: Any]? = nil) {
        guard !userID.isEmpty else {
            config.logger.error("Invalid userID - empty string")
            return
        }

        var properties = properties

        let userChanged = userID != storage.userID
        if userChanged {
            reset()
        }

        storage.userID = userID
        storage.isAnonymous = isAnonymous
        storage.userSignature = properties?.removeValue(forKey: "appcues:user_id_signature") as? String
        analyticsPublisher.publish(TrackingUpdate(type: .profile(interactive: true), properties: properties, isInternal: false))

        // Track a device update on re-identify of the same user, since these will not trigger a new
        // session start, but they do allow a force update of any device props that may have changed
        // outside of the SDK in the application, i.e. push permission.
        // This is interactive: true so it gets batched together with the identify in a single request
        if !userChanged {
            analyticsPublisher.publish(TrackingUpdate(
                type: .event(name: Events.Device.deviceUpdated.rawValue, interactive: true),
                isInternal: true
            ))
        }

        let pushMonitor = container.resolve(PushMonitoring.self)
        pushMonitor.attemptDeferredNotificationResponse()
        // Refresh push status asynchronously so status any changes can still be tracked,
        // but without slowing down the publishing of other events.
        pushMonitor.refreshPushStatus(completion: nil)
    }
}

extension Notification.Name {
    internal static let appcuesReset = Notification.Name("appcuesReset")
}
