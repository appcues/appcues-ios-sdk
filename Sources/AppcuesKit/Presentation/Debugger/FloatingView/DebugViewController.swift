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

    private lazy var debugView = DebugView(mode: mode)

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

    func hide(animated: Bool) {
        debugView.setFloatingView(visible: false, animated: animated, programmatically: true)
    }

    func open(animated: Bool) {
        debugView.setPanelInterface(open: true, animated: animated, programatically: true)
    }

    func close(animated: Bool) {
        debugView.setPanelInterface(open: false, animated: animated, programatically: true)
    }

    func logFleeting(message: String, symbolName: String?) {
        debugView.fleetingLogView.addMessage(message, symbolName: symbolName)
    }
}
