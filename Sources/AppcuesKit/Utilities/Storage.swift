//
//  Storage.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/25/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

internal enum LaunchType {
    case install
    case open
    case update
}

internal class Storage {

    private let config: Appcues.Config

    internal private(set) var launchType: LaunchType

    /// The current  user ID.  Can be a generated anonymous value, or authenticated value provided by application
    @UserDefault("userID", defaultValue: "")
    internal var userID: String

    /// The current `CFBundleShortVersionString` for the application, updated each launch
    @UserDefault("applicationVersion", defaultValue: "")
    internal var applicationVersion: String

    /// The current `CFBundleVersion` for the application, updated each launch
    @UserDefault("applicationBuild", defaultValue: "")
    internal var applicationBuild: String

    init(config: Appcues.Config) {
        self.config = config
        self.launchType = .open

        let previousBuild = applicationBuild
        let currentBuild = Bundle.main.build

        applicationBuild = Bundle.main.build
        applicationVersion = Bundle.main.version

        if previousBuild.isEmpty {
            launchType = .install
        } else if previousBuild != currentBuild {
            launchType = .update
        }
    }
}
