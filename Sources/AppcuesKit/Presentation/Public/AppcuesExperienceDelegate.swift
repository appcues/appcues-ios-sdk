//
//  AppcuesExperienceDelegate.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-17.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

/// A set of methods that allow you to control and respond to Appcues experiences being displayed changes in your app.
@objc
public protocol AppcuesExperienceDelegate: AnyObject {
    /// Asks the delegate for permission to display the Appcues experience.
    /// - Returns: `true` to allow the SDK to display the experience, `false` to refuse the presentaiton.
    func canDisplayExperience(experienceID: String) -> Bool
    /// Notifies the delegate before an Appcues experience is presented.
    func experienceWillAppear()
    /// Notifies the delegate after an Appcues experience is presented.
    func experienceDidAppear()
    /// Notifies the delegate before an Appcues experience is dismissed.
    func experienceWillDisappear()
    /// Notifies the delegate after an Appcues experience is dismissed.
    func experienceDidDisappear()
}
