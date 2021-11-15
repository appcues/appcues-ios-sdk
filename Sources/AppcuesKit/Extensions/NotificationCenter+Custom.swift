//
//  NotificationCenter+Custom.swift
//  AppcuesKit
//
//  Created by James Ellis on 11/12/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

extension NotificationCenter {
    // Note: this NotificationCenter instance should only be used for SDK-global
    // notifications - for example, the UIKitScreenTracking implementatation.
    // Whenever possible, the preferred usage of notifications is via the DIContainer
    // instance of NotificationCenter, to keep messages scoped to the Appcues instance
    // container.
    static var appcues = NotificationCenter()
}
