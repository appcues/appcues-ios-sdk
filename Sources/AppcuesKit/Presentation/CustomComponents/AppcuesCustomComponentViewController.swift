//
//  AppcuesCustomComponentViewController.swift
//  AppcuesKit
//
//  Created by Matt on 2024-10-22.
//  Copyright © 2024 Appcues. All rights reserved.
//

import UIKit

public protocol AppcuesCustomComponentViewController: UIViewController {
    init?(configuration: AppcuesExperiencePluginConfiguration, actionController: AppcuesExperienceActions)

    static var debugConfig: [String: Any]? { get }
}

// Default value to make `debugConfig` optional
public extension AppcuesCustomComponentViewController {
    static var debugConfig: [String: Any]? { nil }
}
