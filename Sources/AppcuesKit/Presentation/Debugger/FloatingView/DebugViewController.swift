//
//  DebugViewController.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-25.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit
import SwiftUI

@available(iOS 13.0, *)
internal class DebugViewController: UIViewController {

    var delegate: DebugViewDelegate? {
        get { debugView.delegate }
        set { debugView.delegate = newValue }
    }

    private var debugView = DebugView()

    var mode: DebugMode {
        didSet {
            setMode(mode)
        }
    }
    // Reference to child view controller
    weak var panelViewController: UIViewController?

    let viewModel: DebugViewModel
    let logger: DebugLogger
    let apiVerifier: APIVerifier
    let deepLinkVerifier: DeepLinkVerifier
    let pushVerifier: PushVerifier

    init(
        viewModel: DebugViewModel,
        logger: DebugLogger,
        apiVerifier: APIVerifier,
        deepLinkVerifier: DeepLinkVerifier,
        pushVerifier: PushVerifier,
        mode: DebugMode
    ) {
        self.viewModel = viewModel
        self.logger = logger
        self.apiVerifier = apiVerifier
        self.deepLinkVerifier = deepLinkVerifier
        self.pushVerifier = pushVerifier
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = debugView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        debugView.floatingView.delegate = self

        setMode(mode)
    }

    func setMode(_ mode: DebugMode) {
        debugView.floatingView.accessibilityLabel = mode.accessibilityLabel
        debugView.floatingView.imageView.image = UIImage(asset: mode.imageAsset)

        // One time setup for debugger mode
        if panelViewController == nil, case .debugger = mode {
            let viewController = UIHostingController(rootView: DebugUI.MainPanelView(
                apiVerifier: apiVerifier,
                deepLinkVerifier: deepLinkVerifier,
                pushVerifier: pushVerifier,
                viewModel: viewModel
            ).environmentObject(logger))
            addChild(viewController)
            debugView.panelWrapperView.addSubview(viewController.view)
            viewController.didMove(toParent: self)
            viewController.view.pin(to: debugView.panelWrapperView)
            panelViewController = viewController
        }

        if case let .debugger(destination) = mode {
            viewModel.navigationDestination = destination
            if destination != nil {
                open(animated: true)
            }
        }
    }

    func show(animated: Bool) {
        debugView.setFloatingView(visible: true, animated: animated, programmatically: true)
    }

    func hide(animated: Bool, notify: Bool = false) {
        debugView.setFloatingView(visible: false, animated: animated, programmatically: true, notify: notify)
    }

    func open(animated: Bool) {
        debugView.setPanelInterface(open: true, animated: animated, programmatically: true)
    }

    func close(animated: Bool) {
        debugView.setPanelInterface(open: false, animated: animated, programmatically: true)
    }

    func logFleeting(message: String, symbolName: String?) {
        debugView.fleetingLogView.addMessage(message, symbolName: symbolName)
    }

    func confirmCapture(screen: Capture, completion: @escaping (Result<String, Error>) -> Void) {
        // hide the FAB but do not notify delegate, since it should not be considered a dismiss of debugger
        hide(animated: true, notify: false)

        let confirmationView = SendCaptureUI.ConfirmationDialogView(
            capture: screen,
            completion: { [weak self] result in
                // dismiss the presented modal
                self?.dismiss(animated: true)
                // show the FAB
                self?.show(animated: true)
                // pass along the result
                completion(result)
            },
            screenName: screen.displayName
        )

        let confirmationViewController = DebugModalViewController(rootView: confirmationView)
        present(confirmationViewController, animated: true)
    }
}

@available(iOS 13.0, *)
extension DebugViewController: FloatingViewDelegate {
    func floatingViewActivated() {
        switch mode {
        case .debugger:
            let isCurrentlyOpen = debugView.floatingView.center == debugView.floatingViewOpenCenter
            debugView.setPanelInterface(open: !isCurrentlyOpen, animated: true, programmatically: false)
            debugView.fleetingLogView.clear()
        case .screenCapture(let authorization):
            delegate?.debugView(did: .screenCapture(authorization))
        }
    }
}

@available(iOS 13.0, *)
private extension DebugMode {
    var accessibilityLabel: String {
        switch self {
        case .debugger:
            return "Appcues Debug Panel"
        case .screenCapture:
            return "Appcues Screen Capture"
        }
    }

    var imageAsset: ImageAsset {
        switch self {
        case .debugger:
            return Asset.Image.debugIcon
        case.screenCapture:
            return Asset.Image.captureScreen
        }
    }
}
