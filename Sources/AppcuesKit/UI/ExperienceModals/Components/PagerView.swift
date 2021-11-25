//
//  PagerView.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-25.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI
import UIKit

internal struct PagerView<Page: View> {
    let axis: Axis
    var pages: [Page]
    @Binding var currentPage: Int
    let infinite: Bool

    var orientation: UIPageViewController.NavigationOrientation {
        switch axis {
        case .horizontal: return .horizontal
        case .vertical: return .vertical
        }
    }
}

extension PagerView: UIViewControllerRepresentable {

    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: PagerView
        var controllers: [UIViewController] = []

        init(_ carouselView: PagerView) {
            parent = carouselView
            controllers = parent.pages.map { UIHostingController(rootView: $0) }
        }

        func pageViewController(
            _ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            guard let index = controllers.firstIndex(of: viewController) else { return nil }
            guard index != 0 else { return parent.infinite ? controllers.last : nil }
            return controllers[index - 1]
        }

        func pageViewController(
            _ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            guard let index = controllers.firstIndex(of: viewController) else { return nil }
            guard index != controllers.count - 1 else { return parent.infinite ? controllers.first : nil }
            return controllers[index + 1]
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            if completed,
               let visibleViewController = pageViewController.viewControllers?.first,
               let index = controllers.firstIndex(of: visibleViewController) {
                parent.currentPage = index
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: orientation)
        pageViewController.dataSource = context.coordinator
        pageViewController.delegate = context.coordinator

        return pageViewController
    }

    func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
        pageViewController.setViewControllers(
            [context.coordinator.controllers[currentPage]],
            direction: .forward,
            animated: true)
    }
}
