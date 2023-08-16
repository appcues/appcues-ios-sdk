//
//  AppcuesExperienceContainerEventHandler.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-17.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

/// A protocol that defines the methods to adopt to respond to changes in an ``AppcuesExperienceContainerViewController``.
@objc
internal protocol AppcuesExperienceContainerEventHandler: AnyObject {

    /// Tells the delegate that the container will appear.
    ///
    /// Should be called from `UIViewController.viewWillAppear()`.
    func containerWillAppear()

    /// Tells the delegate that the container did appear.
    ///
    /// Should be called from `UIViewController.viewDidAppear()`.
    func containerDidAppear()

    /// Tells the delegate that the container will disappear.
    ///
    /// Should be called from `UIViewController.viewWillDisappear()`.
    func containerWillDisappear()

    /// Tells the delegate that the container did disappear.
    ///
    /// Should be called from `UIViewController.viewDidDisappear()`.
    func containerDidDisappear()

    /// Tells the delegate that the step in focus has changed.
    /// - Parameter oldPageIndex: the index prior to the navigation change.
    /// - Parameter newPageIndex: the current index.
    ///
    /// `pageIndex` values refer to the index in the group, **not** the stepIndex in the experience.
    func containerNavigated(from oldPageIndex: Int, to newPageIndex: Int)
}
