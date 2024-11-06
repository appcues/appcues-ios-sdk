//
//  AppcuesCustomComponentViewController.swift
//  AppcuesKit
//
//  Created by Matt on 2024-10-22.
//  Copyright © 2024 Appcues. All rights reserved.
//

import UIKit

/// A protocol that a  `UIViewController` must adopt to allow usage as an Appcues custom component.
public protocol AppcuesCustomComponentViewController: UIViewController {

    /// Optional component configuration for testing in the Appcues Mobile Debugger.
    /// Refer to <doc:CustomComponentConfiguring>.
    static var debugConfig: [String: Any]? { get }

    /// Creates a view controller for use as an Appcues custom component.
    /// - Parameters:
    ///   - configuration: Configuration object that decodes instances of a plugin configuration from an Experience JSON model.
    ///   - actionController: Action options for a custom component to invoke.
    init?(configuration: AppcuesExperiencePluginConfiguration, actionController: AppcuesExperienceActions)
}

// Default value to make `debugConfig` optional
public extension AppcuesCustomComponentViewController {
    /// Optional component configuration for testing in the Appcues Mobile Debugger.
    /// Refer to <doc:CustomComponentConfiguring>.
    static var debugConfig: [String: Any]? { nil }
}
