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

    var delegate: DebugViewDelegate? {
        get { debugView.delegate }
        set { debugView.delegate = newValue }
    }

    private var debugView = DebugView()

    private let panelViewController: UIViewController

    init(wrapping panelViewController: UIViewController) {
        self.panelViewController = panelViewController
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

        addChild(panelViewController)
        debugView.panelWrapperView.addSubview(panelViewController.view)
        panelViewController.didMove(toParent: self)

        panelViewController.view.pin(to: debugView.panelWrapperView)

        let interaction = UIContextMenuInteraction(delegate: self)
        debugView.floatingView.addInteraction(interaction)
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

@available(iOS 13.0, *)
extension DebugViewController: UIContextMenuInteractionDelegate {

    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        let params = UIPreviewParameters()
        params.visiblePath = UIBezierPath(arcCenter: CGPoint(x: 32, y: 32), radius: 36, startAngle: 0, endAngle: 360, clockwise: true)
        return UITargetedPreview(view: debugView.floatingView, parameters: params)
    }

    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let snapshotAction =
            UIAction(title: "Capture Screen",
                     image: UIImage(systemName: "camera.shutter.button")) { [weak self] _ in
                if let capture = UIApplication.shared.windows.first(where: { !($0 is DebugUIWindow) })?.capture() {
                    self?.delegate?.debugCaptured(capture: capture)
                }
            }

            return UIMenu(title: "", children: [snapshotAction])
        }
    }
}
