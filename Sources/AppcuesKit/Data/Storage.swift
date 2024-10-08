//
//  Storage.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/25/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

internal protocol DataStoring: AnyObject {
    /// The device ID. A value generated once upon first initialization of the SDK after installation.
    var deviceID: String { get set }

    /// The current  user ID. Can be a generated anonymous value, or authenticated value provided by application.
    var userID: String { get set }

    /// The current group ID. Optional, and by default `nil` unless the host application has set a group for the user.
    var groupID: String? { get set }

    /// Tracks whether the current user has been identified explicitly as an anonymous user, as opposed to an identified user.
    var isAnonymous: Bool { get set }

    /// The date of the last known time that an experience/flow was shown to the user in this application
    var lastContentShownAt: Date? { get set }

    /// Optional, base 64 encoded signature to use as bearer token on API requests from the current user
    var userSignature: String? { get set }

    /// Push token for APNs
    var pushToken: String? { get set }
}

internal class Storage: DataStoring {

    private enum Key: String {
        case deviceIDv2
        case userID
        case isAnonymous
        case lastContentShownAt
        case groupID
        case userSignature
        case pushToken
    }

    private let config: Appcues.Config

    // Note: not using a property wrapper for UserDefaults, since we want to include the application ID
    //      as part of the suite name
    private lazy var defaults = UserDefaults(suiteName: "com.appcues.storage.\(config.applicationID)")

    internal var deviceID: String {
        get {
            return read(.deviceIDv2, defaultValue: "")
        }
        set {
            write(.deviceIDv2, newValue: newValue)
        }
    }

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

    internal var lastContentShownAt: Date? {
        get {
            return read(.lastContentShownAt, defaultValue: nil)
        }
        set {
            write(.lastContentShownAt, newValue: newValue)
        }
    }

    internal var userSignature: String? {
        get {
            return read(.userSignature, defaultValue: nil)
        }
        set {
            write(.userSignature, newValue: newValue)
        }
    }

    internal var pushToken: String? {
        get {
            return read(.pushToken, defaultValue: nil)
        }
        set {
            write(.pushToken, newValue: newValue)
        }
    }

    init(container: DIContainer) {
        self.config = container.resolve(Appcues.Config.self)

        if self.deviceID.isEmpty {
            // set the device ID once upon first install

            // note: we cannot use UIDevice.current.identifierForVendor
            // for this use case, as we need each app install to have a unique
            // device_id in the Appcues system (even if from same vendor),
            // to be able to correctly target push notification content to the
            // correct devices
            self.deviceID = UUID().appcuesFormatted
        }
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
