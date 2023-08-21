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

    let mode: DebugMode
    private let viewModel: DebugViewModel

    init(viewModel: DebugViewModel, mode: DebugMode) {
        self.viewModel = viewModel
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        debugView.floatingView.accessibilityLabel = mode.accessibilityLabel
        debugView.floatingView.imageView.image = UIImage(asset: mode.imageAsset)
        debugView.floatingView.delegate = self
        view = debugView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if case .debugger = mode {
            let panelViewController = UIHostingController(rootView: DebugUI.MainPanelView(viewModel: viewModel))
            addChild(panelViewController)
            debugView.panelWrapperView.addSubview(panelViewController.view)
            panelViewController.didMove(toParent: self)
            panelViewController.view.pin(to: debugView.panelWrapperView)
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
