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
internal protocol UIDebugging: AnyObject {
    func verifyInstall(token: String)
    func show(mode: DebugMode)
    func showToast(_ toast: DebugToast)
}

/// Methods used by ScreenCapturer
internal protocol ScreenCaptureUI {
    func showConfirmation(screen: Capture, completion: @escaping (Result<String, Error>) -> Void)
    func showToast(_ toast: DebugToast)
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

// controls different flavors of the debugger that can be launched
internal enum DebugMode {
    case debugger(DebugDestination?)      // diagnostics and analytics tools
    case screenCapture(Authorization)     // capture screen image and layout for element targeting
}

@available(iOS 13.0, *)
internal class UIDebugger: UIDebugging {
    private var debugWindow: DebugUIWindow?
    private var toastWindow: ToastUIWindow?

    private var screenCapturer: ScreenCapturer
    private var apiVerifier: APIVerifier
    private var deepLinkVerifier: DeepLinkVerifier
    private var viewModel: DebugViewModel
    private var cancellable: AnyCancellable?

    private let config: Appcues.Config
    private let storage: DataStoring
    private let notificationCenter: NotificationCenter
    private let analyticsPublisher: AnalyticsPublishing
    private let networking: Networking

    private var debugViewController: DebugViewController? {
        return debugWindow?.rootViewController as? DebugViewController
    }

    init(container: DIContainer) {
        self.config = container.resolve(Appcues.Config.self)
        self.storage = container.resolve(DataStoring.self)
        self.analyticsPublisher = container.resolve(AnalyticsPublishing.self)
        self.notificationCenter = container.resolve(NotificationCenter.self)
        self.networking = container.resolve(Networking.self)

        self.screenCapturer = ScreenCapturer(
            config: config,
            networking: networking,
            experienceRenderer: container.resolve(ExperienceRendering.self)
        )
        self.apiVerifier = APIVerifier(
            networking: container.resolve(Networking.self)
        )
        self.deepLinkVerifier = DeepLinkVerifier(
            applicationID: config.applicationID
        )
        self.viewModel = DebugViewModel(storage: storage, accountID: config.accountID, applicationID: config.applicationID)

        notificationCenter.addObserver(self, selector: #selector(appcuesReset), name: .appcuesReset, object: nil)
    }

    func verifyInstall(token: String) {
        deepLinkVerifier.receivedVerification(token: token)
    }

    func show(mode: DebugMode) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.show(mode: mode)
            }
            return
        }

        defer {
            if case let .debugger(destination) = mode {
                viewModel.navigationDestination = destination
                if destination != nil {
                    debugViewController?.open(animated: true)
                }
            }
        }

        if let previousMode = debugViewController?.mode {
            switch (previousMode, mode) {
            case (.debugger, .screenCapture), (.screenCapture, .debugger):
                // Debugger already open but in different mode, dismiss it
                hide()
            default:
                // Debugger already open in desired mode
                return
            }
        }

        guard let windowScene = UIApplication.shared.activeWindowScenes.first else {
            config.logger.error("Could not open debugger")
            return
        }

        analyticsPublisher.register(subscriber: viewModel)
        let rootViewController = DebugViewController(apiVerifier: apiVerifier, deepLinkVerifier: deepLinkVerifier, viewModel: viewModel, mode: mode)
        rootViewController.delegate = self

        cancellable = viewModel.subject.sink {
            guard case .debugger = mode else { return }
            rootViewController.logFleeting(message: $0.name, symbolName: $0.type.symbolName)
        }

        debugWindow = DebugUIWindow(windowScene: windowScene, rootViewController: rootViewController)
    }

    func hide() {
        analyticsPublisher.remove(subscriber: viewModel)
        debugWindow?.isHidden = true
        debugWindow = nil
        cancellable = nil
        viewModel.reset()
    }

    func showToast(_ toast: DebugToast) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.showToast(toast)
            }
            return
        }

        // One-time on-demand set up of the toast window
        if toastWindow == nil, let windowScene = UIApplication.shared.activeWindowScenes.first {
            toastWindow = ToastUIWindow(windowScene: windowScene)
        }

        toastWindow?.showToast(toast)
    }

    @objc
    private func appcuesReset(notification: Notification) {
        viewModel.reset()
    }
}

@available(iOS 13.0, *)
extension UIDebugger: DebugViewDelegate, ScreenCaptureUI {
    func debugView(did event: DebugView.Event) {
        switch event {
        case .hide:
            hide()
        case .open:
            viewModel.currentUserID = storage.userID
            viewModel.isAnonymous = storage.isAnonymous
            apiVerifier.verifyAPI()
        case let .screenCapture(authorization):
            screenCapturer.captureScreen(
                window: UIApplication.shared.windows.first(where: { !$0.isAppcuesWindow }),
                authorization: authorization,
                captureUI: self
            )
        case .show, .close, .reposition:
            break
        }
    }

    func showConfirmation(screen: Capture, completion: @escaping (Result<String, Error>) -> Void) {
        debugViewController?.confirmCapture(screen: screen, completion: completion)
    }
}
