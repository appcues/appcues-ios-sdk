//
//  ToastHostingController.swift
//  AppcuesKit
//
//  Created by James Ellis on 2/28/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import SwiftUI

// Object used to provide a toast view with access to the ToastHosting implementation as an
// environment object.
@available(iOS 13.0, *)
internal final class ToastHostProvider: ObservableObject {
    fileprivate(set) weak var toastHost: ToastHosting?

    func dismissToast(animated: Bool) {
        toastHost?.dismissToast(animated: animated)
    }
}

// Protocol that allows SwiftUI views to access their host (UIHostingController)
// and inform it to dismiss itself.
internal protocol ToastHosting: AnyObject {
    var onDismissToast: ((Bool) -> Void)? { get set }

    func dismissToast(animated: Bool)
}

// A specialized UIHostingController that can be requested to be dismissed from the hosted
// SwiftUI toast view.
@available(iOS 13.0, *)
internal class ToastHostingController<Content: View>: UIHostingController<Content>, ToastHosting {
    private var isToastDismissed = false

    var onDismissToast: ((Bool) -> Void)?

    func dismissToast(animated: Bool) {
        if !isToastDismissed {
            isToastDismissed = true
            onDismissToast?(animated)
        }
    }
}

// Helper that embeds the given toast View and provides access to the ToastHosting implementation
// in a ToastHostProvider environment object.
@available(iOS 13.0, *)
internal extension View {
    func embeddedInToastHostingController() -> ToastHostingController<some View> {
        let provider = ToastHostProvider()
        let hostingAccessingView = environmentObject(provider)
        let hostingController = ToastHostingController(rootView: hostingAccessingView)
        hostingController.view.backgroundColor = .clear
        provider.toastHost = hostingController
        return hostingController
    }
}
