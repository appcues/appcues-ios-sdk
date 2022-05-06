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
internal class AppcuesHostingController<Content: View>: UIHostingController<Content> {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.setNeedsUpdateConstraints()
        preferredContentSize = view.frame.size
    }
}
