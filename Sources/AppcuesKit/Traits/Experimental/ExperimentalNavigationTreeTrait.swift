//
//  ExperimentalNavigationTreeTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-28.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class ExperimentalNavigationTreeTrait: StepDecoratingTrait, ContainerCreatingTrait {
    static let type = "@experimental/navigation-tree"

    required init?(config: [String: Any]?) {
    }

    func decorate(stepController: UIViewController) throws {
        stepController.view.backgroundColor = .systemBackground
    }

    func createContainer(for stepControllers: [UIViewController], targetPageIndex: Int) throws -> ExperienceContainerViewController {
        let navigationController = ExperimentalNavigationController(stepControllers: stepControllers)
        if targetPageIndex != 0 {
            navigationController.navigate(to: targetPageIndex, animated: false)
        }
        return navigationController
    }
}

@available(iOS 13.0, *)
private extension ExperimentalNavigationTreeTrait {
    class ExperimentalNavigationController: UINavigationController, ExperienceContainer {

        var lifecycleHandler: ExperienceContainerLifecycleHandler?
        var pageMonitor: PageMonitor

        private var currentPageIndex: Int = 0 {
            didSet {
                if currentPageIndex != oldValue {
                    pageMonitor.set(currentPage: currentPageIndex)
                }
            }
        }

        private let stepControllers: [UIViewController]

        init(stepControllers: [UIViewController]) {
            self.pageMonitor = PageMonitor(numberOfPages: stepControllers.count, currentPage: 0)
            self.stepControllers = stepControllers

            super.init(rootViewController: stepControllers[0])

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
            view.heightAnchor.constraint(greaterThanOrEqualToConstant: 400).isActive = true
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
            pushViewController(stepControllers[pageIndex], animated: animated)
            currentPageIndex = pageIndex
        }
    }
}
