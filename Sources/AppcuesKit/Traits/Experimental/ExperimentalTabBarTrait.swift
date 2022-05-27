//
//  ExperimentalTabBarTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-28.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class ExperimentalTabBarTrait: StepDecoratingTrait, ContainerCreatingTrait {
    static let type = "@experimental/tab-bar"

    required init?(config: [String: Any]?) {
    }

    func decorate(stepController: UIViewController) throws {
        stepController.view.backgroundColor = .systemBackground
    }

    func createContainer(for stepControllers: [UIViewController], targetPageIndex: Int) throws -> ExperienceContainerViewController {
        let tabController = ExperimentalTabBarController(stepControllers: stepControllers)
        if targetPageIndex != 0 {
            tabController.navigate(to: targetPageIndex, animated: false)
        }
        return tabController
    }
}

@available(iOS 13.0, *)
private extension ExperimentalTabBarTrait {
    class ExperimentalTabBarController: UITabBarController, ExperienceContainer {

        var lifecycleHandler: ExperienceContainerLifecycleHandler?
        var pageMonitor: PageMonitor

        private var currentPageIndex: Int = 0 {
            didSet {
                if currentPageIndex != oldValue {
                    lifecycleHandler?.containerNavigated(from: oldValue, to: currentPageIndex)
                }
            }
        }

        private let stepControllers: [UIViewController]

        init(stepControllers: [UIViewController]) {
            self.pageMonitor = PageMonitor(numberOfPages: stepControllers.count, currentPage: 0)
            self.stepControllers = stepControllers

            super.init(nibName: nil, bundle: nil)

            pageMonitor.addObserver { [weak self] newIndex, oldIndex in
                self?.lifecycleHandler?.containerNavigated(from: oldIndex, to: newIndex)
            }
        }

        @available(*, unavailable)
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            // size for dialog modal
            view.heightAnchor.constraint(greaterThanOrEqualToConstant: 600).isActive = true

            viewControllers = stepControllers
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

        func navigate(to pageIndex: Int, animated: Bool) {
            selectedViewController = stepControllers[pageIndex]
            currentPageIndex = pageIndex
            pageMonitor.set(currentPage: pageIndex)
        }

        override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
            if let newPageIndex = stepControllers.firstIndex(where: { $0.tabBarItem == item }) {
                currentPageIndex = newPageIndex
                pageMonitor.set(currentPage: newPageIndex)
            }
        }
    }
}
