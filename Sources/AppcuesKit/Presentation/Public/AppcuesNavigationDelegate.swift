//
//  AppcuesNavigationDelegate.swift
//  AppcuesKit
//
//  Created by James Ellis on 11/15/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

/// Allows the application to control navigation between screens when triggered by an Appcues experience.
@objc
public protocol AppcuesNavigationDelegate: AnyObject {
    /// Requests the delegate navigate to the given destination, and report completion.
    /// - Parameters:
    ///   - url: The URL of the destination to navigate.
    ///   - openExternally: `true` when the link is intended to open in the default web browser, `false` when an in-app browser.
    ///   - completion: Closure to invoke when navigation is completed, passing `true` if successfully navigated, `false` if not.
    func navigate(to url: URL, openExternally: Bool, completion: @escaping (Bool) -> Void)
}
