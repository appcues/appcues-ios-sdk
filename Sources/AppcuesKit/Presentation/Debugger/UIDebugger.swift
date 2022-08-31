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

    func verifyInstall(token: String) {
        viewModel.receivedVerification(token: token)
    }

    func show(destination: DebugDestination?) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.show(destination: destination)
            }
            return
        }

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
        switch event {
        case .hide:
            hide()
        case .open:
            viewModel.ping()
        case .show, .close, .reposition:
            break
        }
    }

    func debugCaptured(capture: Capture) {
        viewModel.captures.append(capture)

        var request = URLRequest(url: URL(string: "http://localhost:3000/capture")!)
        request.httpMethod = "POST"
        request.httpBody = try? JSONEncoder().encode(capture)
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
            if let url = response?.url?.absoluteString, let statusCode = (response as? HTTPURLResponse)?.statusCode {
                let data = String(data: data ?? Data(), encoding: .utf8) ?? ""
                print("CAPTURE RESPONSE: \(statusCode) \(url) \(data)")
            }
        }

        if let method = request.httpMethod, let url = request.url?.absoluteString {
            let data = String(data: request.httpBody ?? Data(), encoding: .utf8) ?? ""
            print("CAPTURE REQUEST: \(method) \(url) \(data)")
        }

        dataTask.resume()
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
