//
//  DefaultContainerViewController.swift
//  AppcuesKit
//
//  Created by Matt on 2022-02-03.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

internal class DefaultContainerViewController: UIViewController, ExperienceContainerViewController {

    weak var lifecycleHandler: ExperienceContainerLifecycleHandler?
    let pageMonitor: PageMonitor

    var targetPageIndex: Int?

    private let stepControllers: [UIViewController]

    private lazy var stepContainerView = UIView()
    private lazy var preferredHeightConstraint: NSLayoutConstraint = {
        var constraint = view.heightAnchor.constraint(equalToConstant: 0)
        constraint.priority = .defaultLow
        constraint.isActive = true
        return constraint
    }()

    /// **Note:** `stepControllers` are expected to have a preferredContentSize specified.
    init(stepControllers: [UIViewController], targetPageIndex: Int = 0) {
        self.pageMonitor = PageMonitor(numberOfPages: stepControllers.count, currentPage: 0)
        self.stepControllers = stepControllers
        self.targetPageIndex = targetPageIndex

        super.init(nibName: nil, bundle: nil)

        // By default modals cannot be interactively dismissed. The `@appcues/skippable` trait overrides this.
        self.isModalInPresentation = true

        pageMonitor.addObserver { [weak self] newIndex, oldIndex in
            self?.lifecycleHandler?.containerNavigated(from: oldIndex, to: newIndex)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(stepContainerView)
        stepContainerView.pin(to: view)

        navigate(to: targetPageIndex ?? 0, animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lifecycleHandler?.containerWillAppear()

        if let pageIndex = targetPageIndex {
            targetPageIndex = nil
            self.navigate(to: pageIndex, animated: false)
        }
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

        // If the current child controller changes it's preferred size, propagate that to the paging view.
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
