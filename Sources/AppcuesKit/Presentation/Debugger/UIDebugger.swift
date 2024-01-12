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

    private let config: Appcues.Config
    private let storage: DataStoring
    private let notificationCenter: NotificationCenter
    private let analyticsPublisher: AnalyticsPublishing
    private let networking: Networking

    private let subject = PassthroughSubject<LoggedEvent, Never>()
    var eventPublisher: AnyPublisher<LoggedEvent, Never> { subject.eraseToAnyPublisher() }
    private var cancellable = Set<AnyCancellable>()

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

        notificationCenter.addObserver(self, selector: #selector(appcuesReset), name: .appcuesReset, object: nil)
    }

    func verifyInstall(token: String) {
        debugViewController?.deepLinkVerifier.receivedVerification(token: token)
    }

    func show(mode: DebugMode) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.show(mode: mode)
            }
            return
        }

        guard debugViewController?.mode == nil else {
            // Debugger already open, so just update the mode
            debugViewController?.mode = mode
            return
        }

        // Set up the debugger

        guard let windowScene = UIApplication.shared.activeWindowScenes.first else {
            config.logger.error("Could not open debugger")
            return
        }

        let viewModel = DebugViewModel(
            eventPublisher: eventPublisher,
            storage: storage,
            accountID: config.accountID,
            applicationID: config.applicationID
        )

        let debugLogger = DebugLogger(previousLogger: config.logger)
        config.logger = debugLogger

        analyticsPublisher.register(subscriber: self)

        let rootViewController = DebugViewController(
            viewModel: viewModel,
            logger: debugLogger,
            apiVerifier: APIVerifier(networking: networking),
            deepLinkVerifier: DeepLinkVerifier(applicationID: config.applicationID),
            mode: mode
        )
        rootViewController.delegate = self

        eventPublisher
            .sink { [weak rootViewController] in
                guard case .debugger = rootViewController?.mode else { return }
                rootViewController?.logFleeting(message: $0.name, symbolName: $0.type.symbolName)
            }
            .store(in: &cancellable)

        debugWindow = DebugUIWindow(windowScene: windowScene, rootViewController: rootViewController)
    }

    func hide() {
        analyticsPublisher.remove(subscriber: self)
        debugWindow?.isHidden = true
        debugWindow = nil
        cancellable.removeAll()

        // Reset the logger back to the way it was
        if let oldLogger = (config.logger as? DebugLogger)?.previousLogger {
            config.logger = oldLogger
        }
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
        debugViewController?.viewModel.reset()
    }
}

@available(iOS 13.0, *)
extension UIDebugger: DebugViewDelegate, ScreenCaptureUI {
    func debugView(did event: DebugView.Event) {
        switch event {
        case .hide:
            hide()
        case .open:
            debugViewController?.apiVerifier.verifyAPI()
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

@available(iOS 13.0, *)
extension UIDebugger: AnalyticsSubscribing {
    func track(update: TrackingUpdate) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { self.track(update: update) }
            return
        }

        subject.send(LoggedEvent(from: update))
    }
}
