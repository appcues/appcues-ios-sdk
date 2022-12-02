//
//  DefaultContainerViewController.swift
//  AppcuesKit
//
//  Created by Matt on 2022-02-03.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class DefaultContainerViewController: ExperienceContainerViewController {

    weak var lifecycleHandler: ExperienceContainerLifecycleHandler?
    let pageMonitor: PageMonitor

    private let stepControllers: [UIViewController]

    private lazy var stepContainerView = UIView()
    private lazy var preferredHeightConstraint: NSLayoutConstraint = {
        var constraint = view.heightAnchor.constraint(equalToConstant: 0)
        constraint.priority = .defaultLow
        constraint.isActive = true
        return constraint
    }()

    /// **Note:** `stepControllers` are expected to have a preferredContentSize specified.
    init(stepControllers: [UIViewController], pageMonitor: PageMonitor) {
        self.stepControllers = stepControllers
        self.pageMonitor = pageMonitor

        super.init(nibName: nil, bundle: nil)

        // By default modals cannot be interactively dismissed. The `@appcues/skippable` trait overrides this.
        self.isModalInPresentation = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(stepContainerView)
        stepContainerView.pin(to: view)

        navigate(to: pageMonitor.currentPage, animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lifecycleHandler?.containerWillAppear()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        lifecycleHandler?.containerDidAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        lifecycleHandler?.containerWillDisappear()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        lifecycleHandler?.containerDidDisappear()
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)

        // if this container has opted out of updating size, for example background content containers, do not update
        // this view controller's preferredContentSize or height constraint
        if let dynamicSizing = container as? DynamicContentSizing, !dynamicSizing.updatesPreferredContentSize {
            return
        }

        // If the current child controller changes it's preferred size, propagate that this controller's view.
        preferredHeightConstraint.constant = container.preferredContentSize.height
        preferredContentSize = container.preferredContentSize
    }

    func navigate(to pageIndex: Int, animated: Bool) {
        unembedChildViewController(stepControllers[pageMonitor.currentPage])
        embedChildViewController(stepControllers[pageIndex], inSuperview: stepContainerView)

        preferredHeightConstraint.constant = stepControllers[pageIndex].preferredContentSize.height
        pageMonitor.set(currentPage: pageIndex)
    }
}
