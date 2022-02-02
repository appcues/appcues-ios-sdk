//
//  ExperienceStepContainer.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-31.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

/// A `UIViewController` which contains step view controllers to display an `Experience`.
public protocol ExperienceStepContainer: UIViewController {

    /// The delegate object for the experience step container.
    var lifecycleHandler: ExperienceContainerLifecycleHandler? { get set }

    /// Update the step controller in focus.
    /// - Parameter pageIndex: The index of the controller to navigate to.
    ///
    /// The implementation of this method should result in
    /// ``ExperienceContainerLifecycleHandler/containerNavigated(from:to:)`` being called.
    func navigate(to pageIndex: Int)
}
