//
//  Storage.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/25/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

internal class Storage {
    /// The Appcues account ID.
    @UserDefault("accountID", defaultValue: "")
    internal var accountID: String

    /// The current  user ID.  Can be a generated anonymous value, or authenticated value provided by application
    @UserDefault("userID", defaultValue: "")
    internal var userID: String

    /// The current `CFBundleShortVersionString` for the application, updated each launch
    @UserDefault("applicationVersion", defaultValue: "")
    internal var applicationVersion: String

    /// The current `CFBundleVersion` for the application, updated each launch
    @UserDefault("applicationBuild", defaultValue: "")
    internal var applicationBuild: String
}
