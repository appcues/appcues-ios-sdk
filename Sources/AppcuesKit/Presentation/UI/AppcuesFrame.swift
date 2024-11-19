//
//  AppcuesFrame.swift
//  AppcuesKit
//
//  Created by Matt on 2023-07-07.
//  Copyright © 2023 Appcues. All rights reserved.
//

import SwiftUI

/// A SwiftUI view that displays an Appcues experience.
public struct AppcuesFrame: UIViewControllerRepresentable {
    weak var appcues: Appcues?
    let frameID: String

    /// Creates a frame with the given identifier.
    public init(appcues: Appcues?, frameID: String) {
        self.appcues = appcues
        self.frameID = frameID
    }

    /// Creates the view controller object and configures its initial state.
    public func makeUIViewController(context: Context) -> UIViewController {
        let viewController = AppcuesFrameVC()
        appcues?.register(frameID: frameID, for: viewController.frameView, on: viewController)
        return viewController
    }

    /// Updates the state of the specified view controller with new information from SwiftUI.
    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // no-op
    }
}

extension AppcuesFrame {
    class AppcuesFrameVC: UIViewController {
        lazy var frameView = AppcuesFrameView()

        override func loadView() {
            view = frameView
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            // Only want to render the margins specified by the embed style
            viewRespectsSystemMinimumLayoutMargins = false
        }

        override func viewWillLayoutSubviews() {
            super.viewWillLayoutSubviews()

            if view.isHidden {
                preferredContentSize = .zero
            }
        }

        override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
            super.preferredContentSizeDidChange(forChildContentContainer: container)

            // if this container has opted out of updating size, for example background content containers, do not update
            // this view controller's preferredContentSize
            if let dynamicSizing = container as? DynamicContentSizing, !dynamicSizing.updatesPreferredContentSize {
                return
            }

            // Add frame margins to the calculated size. Need to do this because the margins must be set on the FrameView,
            // not the UIViewController it contains which manages the preferredContentSize
            let margins = frameView.directionalLayoutMargins

            preferredContentSize = CGSize(
                width: container.preferredContentSize.width + margins.leading + margins.trailing,
                height: container.preferredContentSize.height + margins.top + margins.bottom
            )
        }
    }
}
