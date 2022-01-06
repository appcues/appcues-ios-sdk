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
    class Config {

        let accountID: String

        let applicationID: String

        var apiHost: String = Networking.defaultAPIHost

        var urlSession: URLSession = Networking.defaultURLSession

        var logger: OSLog = .disabled

        var anonymousIDFactory: () -> String = {
            UIDevice.identifier
        }

        var sessionTimeout: UInt = 1_800 // 30 minutes by default

        var activityCacheSize: UInt = 25

        var activityCacheMaxAge: UInt?

        /// Create an Appcues SDK configuration
        /// - Parameter accountID: Appcues Account ID - a string containing an integer, copied from the Account settings page in Studio.
        /// - Parameter applicationID: Appcues Application ID - a string containing a UUID,
        ///                            copied from the Apps & Installation page in Studio for this iOS application.
        public init(accountID: String, applicationID: String) {
            self.accountID = accountID
            self.applicationID = applicationID
        }

        /// Set the logging status for the configuration.
        /// - Parameter enabled: Whether logging is enabled.
        /// - Returns: The `Configuration` object.
        @discardableResult
        public func logging(_ enabled: Bool) -> Self {
            logger = enabled ? OSLog(appcuesCategory: "general") : .disabled
            return self
        }

        /// Set the API host for the configuration.
        /// - Parameter apiHost: Domain of the API host.
        /// - Returns: The `Configuration` object.
        @discardableResult
        public func apiHost(_ apiHost: String) -> Self {
            self.apiHost = apiHost
            return self
        }

        /// Set the session timeout for the configuration. This timeout value is used to determine if a new session is started
        /// upon the application returning to the foreground. The default value is 1800 seconds (30 minutes).
        /// - Parameter sessionTimeout: The timeout length, in seconds.
        /// - Returns: The `Configuration` object.
        @discardableResult
        public func sessionTimeout(_ sessionTimeout: UInt) -> Self {
            self.sessionTimeout = sessionTimeout
            return self
        }

        /// Set the activity cache size for the configuration.  This value determines how many analytics requests can be
        /// stored on the local device and retried later, in the case of the device network connection being unavailable.
        /// Only the most recent requests, up to this count, are retained.
        /// - Parameter activityCacheSize: The number of items to store, maximum 25, minimum 0.
        /// - Returns: The `Configuration` object.
        @discardableResult
        public func activityCacheSize(_ activityCacheSize: UInt) -> Self {
            self.activityCacheSize = max(0, min(25, activityCacheSize))
            return self
        }

        /// Sets the activity cache max age for the configuration.  This value determines how long an item can be stored
        /// on the local device and retried later, in the case of hte device network connection being unavailable.  Only
        /// requests that are more recent than the max age will be retried - or all, if not set.
        /// - Parameter activityCacheMaxAge: The max age, in seconds, since now.  The default is `nil`, meaning no max age.
        /// - Returns: The `Configuration` object.
        @discardableResult
        public func activityCacheMaxAge(_ activityCacheMaxAge: UInt?) -> Self {
            self.activityCacheMaxAge = activityCacheMaxAge
            return self
        }

        /// Set the `URLSession` instance used by the configuration.
        /// - Parameter apiHost: Domain of the API host.
        /// - Returns: The `Configuration` object.
        ///
        /// Injecting a custom `URLSession` may be useful for testing in combination with `URLSessionConfiguration.protocolClasses`.
        @discardableResult
        public func urlSession(_ urlSession: URLSession) -> Self {
            self.urlSession = urlSession
            return self
        }

        /// Set the factory responsible for generating anonymous user ID's.
        /// - Parameter anonymousIDFactory: Closure that returns an ID as a String.
        /// - Returns: The `Configuration` object.
        @discardableResult
        public func anonymousIDFactory(_ anonymousIDFactory: @escaping () -> String) -> Self {
            self.anonymousIDFactory = anonymousIDFactory
            return self
        }
    }
}
