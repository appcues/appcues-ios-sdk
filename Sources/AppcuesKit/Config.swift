//
//  Config.swift
//  Appcues
//
//  Created by Matt on 2021-10-08.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation
import UIKit
import os.log

// Note: `Config` is a class so that it can be initialized inline with the chained setters. E.g:
// `Config(accountID: "").apiHost("")`. A struct would require initializing as a var first.

/// A configuration object that defines behavior and policies for Appcues.
public class Config {

    let accountID: String

    var apiHost: String = Networking.defaultAPIHost

    var urlSession: URLSession = Networking.defaultURLSession

    var logger: OSLog = .disabled

    var anonymousIDFactory: () -> String = {
        (UIDevice.current.identifierForVendor ?? UUID()).uuidString
    }

    /// Create an Appcues SDK configuration
    /// - Parameter accountID: Appcues Account ID
    public init(accountID: String) {
        self.accountID = accountID
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
