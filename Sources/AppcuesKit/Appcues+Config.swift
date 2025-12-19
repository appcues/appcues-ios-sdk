//
//  Appcues+Config.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-08.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation
import UIKit
import os.log

public extension Appcues {

    // Note: `Config` is a class so that it can be initialized inline with the chained setters. E.g:
    // `Config(accountID: "").apiHost("")`. A struct would require initializing as a var first.

    /// A configuration object that defines behavior and policies for Appcues.
    @objc
    class Config: NSObject {

        let accountID: String

        let applicationID: String

        var apiHost: URL = NetworkClient.defaultAPIHost

        var settingsHost: URL = NetworkClient.defaultSettingsHost

        var urlSession: URLSession = NetworkClient.defaultURLSession

        var webSocketURLSession: URLSession = NetworkClient.webSocketURLSession

        var logger: Logging = OSLog.disabled

        var anonymousIDFactory: () -> String = {
            (UIDevice.current.identifierForVendor ?? UUID()).appcuesFormatted
        }

        var sessionTimeout: UInt = 300  // 5 minutes by default

        var activityStorageMaxSize: UInt = 25

        var activityStorageMaxAge: UInt?

        // Note: this property doesn't have a public setter
        var flushAfterDuration: TimeInterval = 10

        var additionalAutoProperties: [String: Any] = [:]

        var enableUniversalLinks = true

        var enableTextScaling = false

        var enableStepRecoveryObserver = true

        var useSocket = false

        var socketHost: URL = {
            // swiftlint:disable force_unwrapping
            URL(string: "wss://api.appcues.net")!
            // swiftlint:enable force_unwrapping
        }()

        /// Create an Appcues SDK configuration
        /// - Parameter accountID: Appcues Account ID - a string containing an integer, copied from the Account settings page in Studio.
        /// - Parameter applicationID: Appcues Application ID - a string containing a UUID,
        ///                            copied from the Apps & Installation page in Studio for this iOS application.
        @objc
        public init(accountID: String, applicationID: String) {
            self.accountID = accountID
            self.applicationID = applicationID
        }

        /// Set the logging status for the configuration.
        /// - Parameter enabled: Whether logging is enabled.
        /// - Returns: The `Configuration` object.
        ///
        /// Refer to <doc:Logging> for details.
        @discardableResult
        @objc
        public func logging(_ enabled: Bool) -> Self {
            logger = enabled ? OSLog(appcuesCategory: "general") : .disabled
            return self
        }

        /// Set the API host for the configuration.
        /// - Parameter apiHost: Domain of the API host.
        /// - Returns: The `Configuration` object.
        ///
        /// Any path values in the provided `URL` will be discarded.
        @discardableResult
        @objc
        public func apiHost(_ apiHost: URL) -> Self {
            self.apiHost = apiHost
            return self
        }

        /// Set the settings host for the configuration.
        /// - Parameter settingsHost: Domain of the settings host.
        /// - Returns: The `Configuration` object.
        ///
        /// Any path values in the provided `URL` will be discarded.
        @discardableResult
        @objc
        public func settingsHost(_ settingsHost: URL) -> Self {
            self.settingsHost = settingsHost
            return self
        }

        /// Set the session timeout for the configuration. This timeout value is used to determine if a new session is started
        /// after a period of inactivity, in either foreground or background. The default value is 300 seconds (5 minutes).
        /// - Parameter sessionTimeout: The timeout length, in seconds.
        /// - Returns: The `Configuration` object.
        @discardableResult
        @objc
        public func sessionTimeout(_ sessionTimeout: UInt) -> Self {
            self.sessionTimeout = sessionTimeout
            return self
        }

        /// Set the activity storage max size for the configuration. This value determines how many analytics requests can be
        /// stored on the local device and retried later, in the case of the device network connection being unavailable.
        /// Only the most recent requests, up to this count, are retained.
        /// - Parameter activityStorageMaxSize: The number of items to store, maximum 25, minimum 0.
        /// - Returns: The `Configuration` object.
        @discardableResult
        @objc
        public func activityStorageMaxSize(_ activityStorageMaxSize: UInt) -> Self {
            self.activityStorageMaxSize = max(0, min(25, activityStorageMaxSize))
            return self
        }

        /// Sets the activity storage max age for the configuration. This value determines how long an item can be stored
        /// on the local device and retried later, in the case of the device network connection being unavailable. Only
        /// requests that are more recent than the max age will be retried - or all, if not set.
        /// - Parameter activityStorageMaxAge: The max age, in seconds, since now. The default is `nil`, meaning no max age.
        /// - Returns: The `Configuration` object.
        @discardableResult
        @objc
        public func activityStorageMaxAge(_ activityStorageMaxAge: UInt) -> Self {
            self.activityStorageMaxAge = activityStorageMaxAge
            return self
        }

        /// Set the `URLSession` instance used by the configuration.
        /// - Parameter urlSession: `URLSession` object.
        /// - Returns: The `Configuration` object.
        ///
        /// Injecting a custom `URLSession` may be useful for testing in combination with `URLSessionConfiguration.protocolClasses`.
        @discardableResult
        @objc
        public func urlSession(_ urlSession: URLSession) -> Self {
            self.urlSession = urlSession
            return self
        }

        /// Set the factory responsible for generating anonymous user ID's.
        /// - Parameter anonymousIDFactory: Closure that returns an ID as a String.
        /// - Returns: The `Configuration` object.
        @discardableResult
        @objc
        public func anonymousIDFactory(_ anonymousIDFactory: @escaping () -> String) -> Self {
            self.anonymousIDFactory = anonymousIDFactory
            return self
        }

        /// Applies additional auto properties to the configuration. These properties are included by the SDK
        /// in the set of auto properties sent on every tracked analytics event. This function can be called multiple times, and will
        /// apply each update additively. When called with a property name that has already been used, the value will be overwritten.
        ///
        /// All additional auto property names must be unique from those already used internally by the SDK. If a property name conflicts
        /// with an existing auto property generated by the SDK, it is ignored. By convention, internal property names are prefixed with an
        /// underscore character.
        ///
        /// - Parameter additionalAutoProperties: The additional properties to include on every tracked analytics event.
        /// - Returns: The `Configuration` object.
        @discardableResult
        @objc
        public func additionalAutoProperties(_ additionalAutoProperties: [String: Any]) -> Self {
            self.additionalAutoProperties = self.additionalAutoProperties.merging(
                additionalAutoProperties)
            return self
        }

        /// Set the universal link handling preference for the configuration.
        ///
        /// When this property is enabled, the SDK will pass web links that are triggered by an experience back to the host
        /// application to process. The host application should implement the `application(_:continue:restorationHandler:)`
        /// in its `ApplicationDelegate` to return `true` if the link provided in the given `NSUserActivity` has been handled
        /// as a universal link inside the current application, or `false` if not. When a value of `true` is returned, this informs the SDK
        /// that no further link handling is needed. When a value of `false` is returned, the SDK will continue handling the link and open
        /// the web destination in the browser.
        ///
        /// When this property is disabled, any web links triggered by an experience will always be opened in the browser, regardless of
        /// whether it was a universal link that may have been intended to deep link to another screen in the app.
        ///
        /// The default value for this configuration is `true`.
        ///
        /// - Parameter enabled: Whether universal link handling is enabled.
        /// - Returns: The `Configuration` object.
        @discardableResult
        @objc
        public func enableUniversalLinks(_ enabled: Bool) -> Self {
            self.enableUniversalLinks = enabled
            return self
        }

        /// Set the text scaling preference for the configuration.
        ///
        /// When this option is enabled, Appcues content rendered by the SDK will support Dynamic Type, and adjust
        /// to the user's preferred reading size, set in system settings.
        ///
        /// The default value for this configuration is `false`.
        ///
        /// - Parameter enabled: Whether text scaling is enabled.
        /// - Returns: The `Configuration` object.
        @discardableResult
        @objc
        public func enableTextScaling(_ enabled: Bool) -> Self {
            self.enableTextScaling = enabled
            return self
        }

        /// Set the step recovery observation preference for the configuration.
        ///
        /// When this option is enabled, Appcues will detect recoverable step errors and attempt to retry when scroll changes
        /// are observed. Observation uses method swizzling on `UIScrollView`.
        ///
        /// The default value for this configuration is `true`.
        ///
        /// - Parameter enabled: Whether step recovery observation is enabled.
        /// - Returns: The `Configuration` object.
        @discardableResult
        @objc
        public func enableStepRecoveryObserver(_ enabled: Bool) -> Self {
            self.enableStepRecoveryObserver = enabled
            return self
        }

        /// Set the socket connection preference for the configuration.
        ///
        /// When this option is enabled, the SDK will use a WebSocket connection with Phoenix channels
        /// instead of REST API calls for activity qualification. This enables real-time streaming of
        /// qualified content.
        ///
        /// The default value for this configuration is `false`.
        ///
        /// - Parameter enabled: Whether socket connection is enabled.
        /// - Returns: The `Configuration` object.
        @discardableResult
        @objc
        public func useSocket(_ enabled: Bool) -> Self {
            self.useSocket = enabled
            return self
        }

        /// Set the socket host for the configuration.
        /// - Parameter socketHost: Domain of the socket host.
        /// - Returns: The `Configuration` object.
        ///
        /// Any path values in the provided `URL` will be discarded.
        @discardableResult
        @objc
        public func socketHost(_ socketHost: URL) -> Self {
            self.socketHost = socketHost
            return self
        }
    }
}
