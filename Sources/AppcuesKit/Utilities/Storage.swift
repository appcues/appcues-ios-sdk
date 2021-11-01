//
//  Storage.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/25/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

internal class Storage {

    private enum Key: String {
        case userID = "userID"
        case applicationVersion = "applicationVersion"
        case applicationBuild = "applicationBuild"
    }

    private let config: Appcues.Config

    // Note: not using a property wrapper for UserDefaults, since we want to include the account ID
    //      as part of the suite name
    private lazy var defaults = UserDefaults(suiteName: "com.appcues.storage.\(config.accountID)")

    init(container: DIContainer) {
        self.config = container.resolve(Appcues.Config.self)
    }

    /// The current  user ID.  Can be a generated anonymous value, or authenticated value provided by application
    internal var userID: String {
        get {
            return read(.userID, defaultValue: "")
        }
        set {
            write(.userID, newValue: newValue)
        }
    }

    /// The current `CFBundleShortVersionString` for the application, updated each launch
    internal var applicationVersion: String {
        get {
            return read(.applicationVersion, defaultValue: "")
        }
        set {
            write(.applicationVersion, newValue: newValue)
        }
    }

    /// The current `CFBundleVersion` for the application, updated each launch
    internal var applicationBuild: String {
        get {
            return read(.applicationBuild, defaultValue: "")
        }
        set {
            write(.applicationBuild, newValue: newValue)
        }
    }

    private func read<T>(_ key: Key, defaultValue: T) -> T {
        return defaults?.object(forKey: key.rawValue) as? T ?? defaultValue
    }

    private func write<T>(_ key: Key, newValue: T) {
        defaults?.set(newValue, forKey: key.rawValue)
    }
}
