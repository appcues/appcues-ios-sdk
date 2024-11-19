//
//  DynamicContentSizing.swift
//  AppcuesKit
//
//  Created by James Ellis on 8/17/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

/// Used to inform a container `UIViewController` whether it should update it's `preferredContentSize` based
/// on the updated size of this `UIContentContainer`.
internal protocol DynamicContentSizing: UIContentContainer {
    var updatesPreferredContentSize: Bool { get set }
}
