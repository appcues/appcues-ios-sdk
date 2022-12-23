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

    func clone(_ button: UIButton, type: String)
    func clone(_ label: UILabel, type: String)
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
    private var template: Template
    private var cancellable: AnyCancellable?

    private let config: Appcues.Config
    private let storage: DataStoring
    private let notificationCenter: NotificationCenter
    private let analyticsPublisher: AnalyticsPublishing
    private let experienceRenderer: ExperienceRendering

    init(container: DIContainer) {
        self.config = container.resolve(Appcues.Config.self)
        self.storage = container.resolve(DataStoring.self)
        self.analyticsPublisher = container.resolve(AnalyticsPublishing.self)
        self.notificationCenter = container.resolve(NotificationCenter.self)
        self.experienceRenderer = container.resolve(ExperienceRendering.self)

        // resolving will init InteractionMonitor, which sets up the swizzling of
        // UIApplication for click to track
        _ = container.resolve(InteractionMonitor.self)

        self.viewModel = DebugViewModel(
            networking: container.resolve(Networking.self),
            accountID: config.accountID,
            applicationID: config.applicationID,
            currentUserID: storage.userID,
            isAnonymous: storage.isAnonymous)
        self.template = Template()

        notificationCenter.addObserver(self, selector: #selector(appcuesReset), name: .appcuesReset, object: nil)
        NotificationCenter.appcues.addObserver(self, selector: #selector(startTemplateCapture), name: .appcuesTemplateCapture, object: nil)
        NotificationCenter.appcues.addObserver(self, selector: #selector(showTemplatePreview), name: .appcuesTemplatePreview, object: nil)
        NotificationCenter.appcues.addObserver(self, selector: #selector(startClone), name: .appcuesTemplateClone, object: nil)
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
        let panelViewController = UIHostingController(rootView: DebugUI.MainPanelView(viewModel: viewModel).environmentObject(template))
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

    @objc
    private func startTemplateCapture(notification: Notification) {
        DispatchQueue.main.async { [self] in
            if !viewModel.isAnalyzingForTemplate {
                if case .screen = viewModel.latestEvent?.type, let lastScreenName = viewModel.latestEvent?.name {
                    capture(screenName: lastScreenName)
                }
            }

            viewModel.isAnalyzingForTemplate = !viewModel.isAnalyzingForTemplate
        }
    }

    @objc
    private func showTemplatePreview(notification: Notification) {
        (debugWindow?.rootViewController as? DebugViewController)?.close(animated: true)

        DispatchQueue.main.async { [self] in
            viewModel.isAnalyzingForTemplate = false
        }

        guard let experience = try? template.experience() else {
            return
        }

        let data = ExperienceData(experience, trigger: .preview, published: false)
        experienceRenderer.show(experience: data, completion: nil)
    }

    @objc
    private func startClone(notification: Notification) {
        (debugWindow?.rootViewController as? DebugViewController)?.close(animated: true)
    }

    func clone(_ button: UIButton, type: String) {
        let buttonKeyPath: ReferenceWritableKeyPath<Template, ExperienceComponent.Style>
        let buttonTextKeyPath: ReferenceWritableKeyPath<Template, ExperienceComponent.Style>

        switch type {
        case "primaryButton":
            buttonKeyPath = \.primaryButtonStyle
            buttonTextKeyPath = \.primaryButtonTextStyle
        case "secondaryButton":
            buttonKeyPath = \.secondaryButtonStyle
            buttonTextKeyPath = \.secondaryButtonTextStyle
        default:
            return
        }

        template[keyPath: buttonKeyPath].borderWidth = button.layer.borderWidth

        template[keyPath: buttonKeyPath].cornerRadius = nil

        if let backgroundColor = button.backgroundColor?.hexString {
            template[keyPath: buttonKeyPath].backgroundColor = ExperienceComponent.Style.DynamicColor(light: backgroundColor)
            template[keyPath: buttonKeyPath].cornerRadius = button.layer.cornerRadius
        } else if button.subviews.first?.description.hasPrefix("<_UISystemBackgroundView") == true, let backgroundViewColor = button.subviews.first?.subviews.first?.backgroundColor?.hexString {
            template[keyPath: buttonKeyPath].backgroundColor = ExperienceComponent.Style.DynamicColor(light: backgroundViewColor)
            if let cornerRadius = button.subviews.first?.subviews.first?.layer.cornerRadius {
                template[keyPath: buttonKeyPath].cornerRadius = cornerRadius
            }
        } else {
            template[keyPath: buttonKeyPath].backgroundColor = nil
        }

        if let fontSize = button.titleLabel?.font.pointSize {
            template[keyPath: buttonTextKeyPath].fontSize = Double(fontSize)
        }

        template[keyPath: buttonTextKeyPath].fontName = button.titleLabel?.font.fontName.formattedFontName
        if let textColor = button.titleLabel?.textColor.hexString {
            template[keyPath: buttonTextKeyPath].foregroundColor = ExperienceComponent.Style.DynamicColor(light: textColor)
        }
    }

    func clone(_ label: UILabel, type: String) {
        let textKeyPath: ReferenceWritableKeyPath<Template, ExperienceComponent.Style>

        switch type {
        case "headerText":
            textKeyPath = \.headerTextStyle
        case "bodyText":
            textKeyPath = \.bodyTextStyle
        default:
            return
        }

        template[keyPath: textKeyPath].fontSize = Double(label.font.pointSize)
        template[keyPath: textKeyPath].fontName = label.font.fontName
        template[keyPath: textKeyPath].foregroundColor = ExperienceComponent.Style.DynamicColor(light: label.textColor.hexString)
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
}

@available(iOS 13.0, *)
extension UIDebugger: AnalyticsSubscribing {
    func track(update: TrackingUpdate) {
        // Publishing changes must from the main thread.
        DispatchQueue.main.async {
            self.viewModel.currentUserID = self.storage.userID
            self.viewModel.isAnonymous = self.storage.isAnonymous
            self.viewModel.addUpdate(update)

            if self.viewModel.isAnalyzingForTemplate, case .screen(let screenName) = update.type {
                self.capture(screenName: screenName)
            }
        }
    }

    func capture(screenName: String) {
        guard template.shouldCapture(screenName: screenName), let window = UIApplication.shared.windows.first(where: { !($0 is DebugUIWindow) }) else { return }

        if let capture = window.capture(name: screenName) {
            template.addCapture(capture: capture)
        }
    }
}
