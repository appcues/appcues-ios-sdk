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
    func show(destination: DebugDestination?)
}

/// Navigation destinations within the debugger
internal enum DebugDestination {
    /// Font list screen
    case fonts

    init?(pathToken: String?) {
        switch pathToken {
        case "fonts": self = .fonts
        default: return nil
        }
    }
}

@available(iOS 13.0, *)
internal class UIDebugger: UIDebugging {
    private var debugWindow: UIWindow?

    private var viewModel: DebugViewModel
    private var cancellable: AnyCancellable?

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

    func show(destination: DebugDestination?) {
        defer {
            viewModel.navigationDestination = destination
            if destination != nil {
                (debugWindow?.rootViewController as? DebugViewController)?.open(animated: true)
            }
        }

        // Debugger already open
        guard debugWindow == nil else { return }

        guard let windowScene = UIApplication.shared.activeWindowScenes.first else {
            config.logger.error("Could not open debugger")
            return
        }

        analyticsPublisher.register(subscriber: self)
        let panelViewController = UIHostingController(rootView: DebugUI.MainPanelView(viewModel: viewModel))
        let rootViewController = DebugViewController(wrapping: panelViewController)
        rootViewController.delegate = self

        cancellable = viewModel.$latestEvent.sink {
            guard let loggedEvent = $0 else { return }
            rootViewController.logFleeting(message: loggedEvent.name, symbolName: loggedEvent.type.symbolName)
        }

        debugWindow = DebugUIWindow(windowScene: windowScene, rootViewController: rootViewController)
    }

    func hide() {
        analyticsPublisher.remove(subscriber: self)
        debugWindow?.isHidden = true
        debugWindow = nil
        cancellable = nil
        viewModel.reset()
    }

    @objc
    private func appcuesReset(notification: Notification) {
        self.viewModel.reset()
    }
}

@available(iOS 13.0, *)
extension UIDebugger: DebugViewDelegate {
    func debugView(did event: DebugView.Event) {
        if case .hide = event {
            hide()
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
            self.viewModel.addUpdate(update)
        }
    }
}
