//
//  UIDebugger.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-25.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit
import SwiftUI
import Combine

@available(iOS 13.0, *)
internal protocol UIDebugging {
    func show()
}

@available(iOS 13.0, *)
internal class UIDebugger: UIDebugging {
    private var debugWindow: UIWindow?

    private var viewModel: DebugViewModel
    private var cancellables: Set<AnyCancellable> = []

    private let config: Appcues.Config
    private let storage: DataStoring
    private let notificationCenter: NotificationCenter
    private let analyticsPublisher: AnalyticsPublishing

    init(container: DIContainer) {
        self.config = container.resolve(Appcues.Config.self)
        self.storage = container.resolve(DataStoring.self)
        self.analyticsPublisher = container.resolve(AnalyticsPublishing.self)
        self.notificationCenter = container.resolve(NotificationCenter.self)

        self.viewModel = DebugViewModel(
            networking: container.resolve(Networking.self),
            accountID: config.accountID,
            applicationID: config.applicationID,
            currentUserID: storage.userID,
            isAnonymous: storage.isAnonymous)

        notificationCenter.addObserver(self, selector: #selector(appcuesReset), name: .appcuesReset, object: nil)
    }

    func show() {
        guard debugWindow == nil else { return }
        guard let windowScene = UIApplication.shared.activeWindowScenes.first else {
            config.logger.error("Could not open debugger")
            return
        }

        analyticsPublisher.register(subscriber: self)
        let panelViewController = UIHostingController(rootView: DebugUI.MainPanelView(viewModel: viewModel))
        let rootViewController = DebugViewController(wrapping: panelViewController)
        rootViewController.delegate = self

        viewModel.$unreadCount.sink {
            rootViewController.unreadCount = $0
        }
        .store(in: &cancellables)

        viewModel.$latestEvent.sink {
            guard let loggedEvent = $0 else { return }
            rootViewController.logFleeting(message: loggedEvent.name, symbolName: loggedEvent.type.symbolName)
        }
        .store(in: &cancellables)

        debugWindow = DebugUIWindow(windowScene: windowScene, rootViewController: rootViewController)
    }

    func hide() {
        analyticsPublisher.remove(subscriber: self)
        debugWindow?.isHidden = true
        debugWindow = nil
        cancellables.removeAll()
    }

    @objc
    private func appcuesReset(notification: Notification) {
        self.viewModel.reset()
    }
}

@available(iOS 13.0, *)
extension UIDebugger: DebugViewDelegate {
    func debugView(did event: DebugView.Event) {
        switch event {
        case .open:
            viewModel.unreadCount = 0
        case .hide:
            hide()
        case .show, .close, .reposition:
            break
        }
    }
}

@available(iOS 13.0, *)
extension UIDebugger: AnalyticsSubscribing {
    func track(update: TrackingUpdate) {
        // Publishing changes must from the main thread.
        DispatchQueue.main.async {
            self.viewModel.currentUserID = self.storage.userID
            self.viewModel.isAnonymous = self.storage.isAnonymous
            self.viewModel.addEvent(DebugViewModel.LoggedEvent(from: update))
        }
    }
}
