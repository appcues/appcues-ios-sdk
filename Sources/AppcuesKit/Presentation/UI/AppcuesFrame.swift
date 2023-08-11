//
//  AppcuesFrame.swift
//  AppcuesKit
//
//  Created by Matt on 2023-07-07.
//  Copyright © 2023 Appcues. All rights reserved.
//

import SwiftUI

/// A SwiftUI view that displays an Appcues experience.
@available(iOS 13.0, *)
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

@available(iOS 13.0, *)
extension AppcuesFrame {
    class AppcuesFrameVC: UIViewController {
        lazy var frameView = AppcuesFrameView()

        override func loadView() {
            view = frameView
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

            preferredContentSize = container.preferredContentSize
        }
    }
}
