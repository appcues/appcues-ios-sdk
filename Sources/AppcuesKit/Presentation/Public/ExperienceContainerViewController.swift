//
//  ExperienceContainerViewController.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-31.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

/// A `UIViewController` which contains step view controllers to display an `Experience`.
@objc
public protocol ExperienceContainer {

    /// The delegate object for the experience step container.
    var lifecycleHandler: ExperienceContainerLifecycleHandler? { get set }

    /// The object maintaining current page state and observers.
    var pageMonitor: PageMonitor { get }

    /// Update the step controller in focus.
    /// - Parameter pageIndex: The index of the controller to navigate to.
    /// - Parameter animated: Pass `true` to animate the navigation change (if animation supported); otherwise, pass `false`.
    ///
    /// The implementation of this method should result in
    /// ``ExperienceContainerLifecycleHandler/containerNavigated(from:to:)`` being called.
    func navigate(to pageIndex: Int, animated: Bool)
}

/// A convenience typealias for a `UIViewController` that is also an `ExperienceContainer`
public typealias ExperienceContainerViewController = ExperienceContainer & UIViewController
