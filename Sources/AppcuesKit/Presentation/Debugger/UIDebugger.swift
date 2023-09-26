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

    private var viewModel: DebugViewModel
    private var cancellable: AnyCancellable?

    private let config: Appcues.Config
    private let storage: DataStoring
    private let notificationCenter: NotificationCenter
    private let analyticsPublisher: AnalyticsPublishing
    private let networking: Networking
    private let experienceRenderer: ExperienceRendering

    private var debugViewController: DebugViewController? {
        return debugWindow?.rootViewController as? DebugViewController
    }

    init(container: DIContainer) {
        self.config = container.resolve(Appcues.Config.self)
        self.storage = container.resolve(DataStoring.self)
        self.analyticsPublisher = container.resolve(AnalyticsPublishing.self)
        self.notificationCenter = container.resolve(NotificationCenter.self)
        self.networking = container.resolve(Networking.self)
        self.experienceRenderer = container.resolve(ExperienceRendering.self)

        self.viewModel = DebugViewModel(
            networking: container.resolve(Networking.self),
            accountID: config.accountID,
            applicationID: config.applicationID,
            currentUserID: storage.userID,
            isAnonymous: storage.isAnonymous,
            bundleFontsPath: config.bundleFontsPath
        )

        notificationCenter.addObserver(self, selector: #selector(appcuesReset), name: .appcuesReset, object: nil)
    }

    func verifyInstall(token: String) {
        viewModel.receivedVerification(token: token)
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

        analyticsPublisher.register(subscriber: self)
        let rootViewController = DebugViewController(viewModel: viewModel, mode: mode)
        rootViewController.delegate = self

        cancellable = viewModel.$latestEvent.sink {
            guard case .debugger = mode, let loggedEvent = $0 else { return }
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
        self.viewModel.reset()
        self.viewModel.currentUserID = self.storage.userID
        self.viewModel.isAnonymous = self.storage.isAnonymous
    }
}

@available(iOS 13.0, *)
extension UIDebugger: DebugViewDelegate {
    func debugView(did event: DebugView.Event) {
        switch event {
        case .hide:
            hide()
        case .open:
            viewModel.ping()
        case let .screenCapture(authorization):
            captureScreen(authorization: authorization)
        case .show, .close, .reposition:
            break
        }
    }

    private func captureScreen(authorization: Authorization) {
        guard experienceRenderer.experienceData(forContext: .modal) == nil else {
            experienceRenderer.dismiss(inContext: .modal, markComplete: false) { _ in
                self.captureScreen(authorization: authorization)
            }
            return
        }

        guard let debugViewController = debugViewController,
              let window = UIApplication.shared.windows.first(where: { !$0.isAppcuesWindow }),
              let screenshot = window.screenshot(),
              let layout = Appcues.elementTargeting.captureLayout() else {
            let toast = DebugToast(message: .screenCaptureFailure, style: .failure)
            showToast(toast)
            return
        }

        let timestamp = Date()
        var capture = Capture(
            appId: config.applicationID,
            displayName: window.screenCaptureDisplayName(),
            screenshotImageUrl: nil,
            layout: layout,
            metadata: Capture.Metadata(insets: Capture.Insets(window.safeAreaInsets)),
            timestamp: timestamp,
            screenshot: screenshot
        )

        // show confirmation dialog
        debugViewController.confirmCapture(screen: capture) { [weak self] result in
            guard let self = self else { return }

            if case let .success(name) = result {
                // get updated name
                capture.displayName = name

                // save the screen into the account/app
                self.saveScreen(debugViewController: debugViewController, capture: capture, authorization: authorization)
            }
        }
    }

    private func saveScreen(debugViewController: DebugViewController, capture: Capture, authorization: Authorization) {
        self.saveScreenCapture(networking: self.networking, screen: capture, authorization: authorization) { result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    let toast = DebugToast(message: .screenCaptureSuccess(displayName: capture.displayName), style: .success)
                    self.showToast(toast)
                }
            case .failure:
                DispatchQueue.main.async {
                    let toast = DebugToast(message: .screenUploadFailure, style: .failure, duration: 6.0) {
                        // onRetry - recursively call save to try again
                        self.saveScreen(debugViewController: debugViewController, capture: capture, authorization: authorization)
                    }
                    self.showToast(toast)
                }
            }
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
