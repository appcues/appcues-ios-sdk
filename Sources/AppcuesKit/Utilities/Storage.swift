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
        case deviceID
        case userID
        case isAnonymous
        case applicationVersion
        case applicationBuild
        case lastContentShownAt
        case groupID
    }

    private let config: Appcues.Config

    // Note: not using a property wrapper for UserDefaults, since we want to include the application ID
    //      as part of the suite name
    private lazy var defaults = UserDefaults(suiteName: "com.appcues.storage.\(config.applicationID)")

    /// The device ID.  A value generated once upon first initialization of the SDK after installation.
    internal var deviceID: String {
        get {
            return read(.deviceID, defaultValue: "")
        }
        set {
            write(.deviceID, newValue: newValue)
        }
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

    internal var groupID: String? {
        get {
            return read(.groupID, defaultValue: nil)
        }
        set {
            write(.groupID, newValue: newValue)
        }
    }

    internal var isAnonymous: Bool {
        get {
            return read(.isAnonymous, defaultValue: true)
        }
        set {
            write(.isAnonymous, newValue: newValue)
        }
    }

    /// The date of the last known time that an experience/flow was shown to the user in this application
    internal var lastContentShownAt: Date? {
        get {
            return read(.lastContentShownAt, defaultValue: nil)
        }
        set {
            write(.lastContentShownAt, newValue: newValue)
        }
    }

    init(container: DIContainer) {
        self.config = container.resolve(Appcues.Config.self)
    }

    private func read<T>(_ key: Key, defaultValue: T) -> T {
        return defaults?.object(forKey: key.rawValue) as? T ?? defaultValue
    }

    private func write<T>(_ key: Key, newValue: T?) {
        guard let newValue = newValue else {
            defaults?.removeObject(forKey: key.rawValue)
            return
        }

        defaults?.set(newValue, forKey: key.rawValue)
    }
}
