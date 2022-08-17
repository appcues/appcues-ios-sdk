//
//  AppcuesHostingController.swift
//  AppcuesKit
//
//  Created by Matt on 2021-12-10.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

/// A `UIHostingController` that properly handles content size changes and removes the extra spacing added in iOS 15.
///
/// Reference: https://stackoverflow.com/a/69359296
@available(iOS 13.0, *)
internal class AppcuesHostingController<Content: View>: UIHostingController<Content>, DynamicContentSizing {

    // By default, changes in preferred content size from this hosting controller should be propagated up
    // to any containers embedding it, to allow for dynamic sizing based on the content.
    // This will be overriden to false for content that does not determine size, such as background content.
    var updatesPreferredContentSize = true

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.setNeedsUpdateConstraints()
        preferredContentSize = view.frame.size
    }
}
