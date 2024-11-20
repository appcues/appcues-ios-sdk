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

internal protocol UIDebugging: AnyObject {
    @MainActor func verifyInstall(token: String)
    @MainActor func show(mode: DebugMode)
    @MainActor func showToast(_ toast: DebugToast)
}

/// Methods used by ScreenCapturer
internal protocol ScreenCaptureUI {
    @MainActor func showConfirmation(screen: Capture, completion: @escaping (Result<String, Error>) -> Void)
    @MainActor func showToast(_ toast: DebugToast)
}

/// Navigation destinations within the debugger
internal enum DebugDestination {
    /// Font list screen
    case fonts
    case plugins

    init?(pathToken: String?) {
        switch pathToken {
        case "fonts": self = .fonts
        case "plugins": self = .plugins
        default: return nil
        }
    }
}

// controls different flavors of the debugger that can be launched
internal enum DebugMode {
    case debugger(DebugDestination?)      // diagnostics and analytics tools
    case screenCapture(Authorization)     // capture screen image and layout for element targeting
}

internal class UIDebugger: UIDebugging {
    private var debugWindow: DebugUIWindow?
    private var toastWindow: ToastUIWindow?

    private var screenCapturer: ScreenCapturer

    private let config: Appcues.Config
    private let storage: DataStoring
    private let notificationCenter: NotificationCenter
    private let analyticsPublisher: AnalyticsPublishing
    private let networking: Networking
    private let pushVerifier: PushVerifier

    private let subject = PassthroughSubject<LoggedEvent, Never>()
    var eventPublisher: AnyPublisher<LoggedEvent, Never> { subject.eraseToAnyPublisher() }
    private var cancellable = Set<AnyCancellable>()

    @MainActor
    private var debugViewController: DebugViewController? {
        return debugWindow?.rootViewController as? DebugViewController
    }

    init(container: DIContainer) {
        self.config = container.resolve(Appcues.Config.self)
        self.storage = container.resolve(DataStoring.self)
        self.analyticsPublisher = container.resolve(AnalyticsPublishing.self)
        self.notificationCenter = container.resolve(NotificationCenter.self)
        self.networking = container.resolve(Networking.self)
        self.pushVerifier = container.resolve(PushVerifier.self)

        self.screenCapturer = ScreenCapturer(
            config: config,
            networking: networking,
            experienceRenderer: container.resolve(ExperienceRendering.self)
        )

        notificationCenter.addObserver(self, selector: #selector(appcuesReset), name: .appcuesReset, object: nil)
    }

    @MainActor
    func verifyInstall(token: String) {
        debugViewController?.deepLinkVerifier.receivedVerification(token: token)
    }

    @MainActor
    func show(mode: DebugMode) {
        guard debugViewController?.mode == nil else {
            // Debugger already open, so just update the mode
            debugViewController?.mode = mode
            return
        }

        // Set up the debugger

        guard let windowScene = UIApplication.shared.mainWindowScene else {
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
            pushVerifier: pushVerifier,
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

    @MainActor
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

    @MainActor
    func showToast(_ toast: DebugToast) {
        // One-time on-demand set up of the toast window
        if toastWindow == nil, let windowScene = UIApplication.shared.mainWindowScene {
            toastWindow = ToastUIWindow(windowScene: windowScene)
        }

        toastWindow?.showToast(toast)
    }

    @MainActor
    @objc
    private func appcuesReset(notification: Notification) {
        debugViewController?.viewModel.reset()
    }
}

extension UIDebugger: DebugViewDelegate, ScreenCaptureUI {
    func debugView(did event: DebugView.Event) {
        Task {
            switch event {
            case .hide:
                await hide()
            case .open:
                await debugViewController?.apiVerifier.verifyAPI()
            case let .screenCapture(authorization):
                await screenCapturer.captureScreen(
                    window: UIApplication.shared.appWindow,
                    authorization: authorization,
                    captureUI: self
                )
            case .show, .close, .reposition:
                break
            }
        }
    }

    @MainActor
    func showConfirmation(screen: Capture, completion: @escaping (Result<String, Error>) -> Void) {
        debugViewController?.confirmCapture(screen: screen, completion: completion)
    }
}

extension UIDebugger: AnalyticsSubscribing {
    func track(update: TrackingUpdate) {
        Task { @MainActor in
            subject.send(LoggedEvent(from: update))
        }
    }
}
