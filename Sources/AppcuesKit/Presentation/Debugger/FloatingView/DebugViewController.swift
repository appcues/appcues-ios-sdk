//
//  DebugViewController.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-25.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class DebugViewController: UIViewController {

    private var debugView = DebugView()

    private let panelViewController: UIViewController

    init(wrapping panelViewController: UIViewController, dismissHandler: @escaping () -> Void) {
        self.panelViewController = panelViewController
        super.init(nibName: nil, bundle: nil)

        debugView.didDismiss = dismissHandler
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

        addChild(panelViewController)
        debugView.panelWrapperView.addSubview(panelViewController.view)
        panelViewController.didMove(toParent: self)

        panelViewController.view.pin(to: debugView.panelWrapperView)
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
}
