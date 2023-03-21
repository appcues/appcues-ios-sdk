//
//  UIWindow+Appcues.swift
//  AppcuesKit
//
//  Created by James Ellis on 3/22/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit

@objc
public extension UIWindow {
    /// Determines if this `UIWindow` is an internal Appcues SDK window.
    ///
    /// Implementations of `AppcuesElementTargeting` may need this value to reliably exclude any Appcues content windows
    /// that are overlaid on top of the application, when capturing screen layout information.
    @available(iOS 13.0, *)
    var isAppcuesWindow: Bool {
        return self is DebugUIWindow
    }
}
