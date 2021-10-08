//
//  Config.swift
//  Appcues
//
//  Created by Matt on 2021-10-08.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

// Note: `Config` is a class so that it can be initialized inline with the chained setters. E.g:
// `Config(accountID: "").apiHost("")`. A struct would require initializing as a var first.

/// A configuration object that defines behavior and policies for Appcues.
public class Config {

    let accountID: String

    var apiHost: String = Networking.defaultAPIHost

    var urlSession: URLSession = Networking.defaultURLSession

    /// Create an Appcues SDK configuration
    /// - Parameter accountID: Appcues Account ID
    public init(accountID: String) {
        self.accountID = accountID
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
}
