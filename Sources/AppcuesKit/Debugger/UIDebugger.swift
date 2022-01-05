//
//  UIDebugger.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-25.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit
import SwiftUI

internal class UIDebugger {
    private var debugWindow: UIWindow?

    private var viewModel: DebugViewModel

    private let config: Appcues.Config
    private let storage: Storage
    private let notificationCenter: NotificationCenter

    init(container: DIContainer) {
        self.config = container.resolve(Appcues.Config.self)
        self.storage = container.resolve(Storage.self)
        self.notificationCenter = container.resolve(NotificationCenter.self)

        self.viewModel = DebugViewModel(
            accountID: config.accountID,
            applicationID: config.applicationID,
            currentUserID: storage.userID,
            isAnonymous: storage.isAnonymous)

        registerForAnalyticsUpdates(container)

        notificationCenter.addObserver(self, selector: #selector(appcuesReset), name: .appcuesReset, object: nil)
    }

    func show() {
        guard debugWindow == nil else { return }
        guard let windowScene = UIApplication.shared.activeWindowScenes.first else {
            config.logger.error("Could not open debugger")
            return
        }

        let panelViewController = UIHostingController(rootView: DebugUI.MainPanelView(viewModel: viewModel))

        let rootViewController = DebugViewController(wrapping: panelViewController, dismissHandler: hide)
        debugWindow = DebugUIWindow(windowScene: windowScene, rootViewController: rootViewController)
    }

    func hide() {
        debugWindow?.isHidden = true
        debugWindow = nil
    }

    @objc
    private func appcuesReset(notification: Notification) {
        self.viewModel.reset()
    }
}

extension UIDebugger: AnalyticsSubscriber {
    func track(update: TrackingUpdate) {
        // Publishing changes must from the main thread.
        DispatchQueue.main.async {
            self.viewModel.currentUserID = self.storage.userID
            self.viewModel.isAnonymous = self.storage.isAnonymous
            self.viewModel.addEvent(DebugViewModel.LoggedEvent(from: update))
        }
    }
}
