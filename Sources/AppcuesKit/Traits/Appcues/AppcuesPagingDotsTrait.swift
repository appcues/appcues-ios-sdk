//
//  AppcuesPagingDotsTrait.swift
//  Appcues
//
//  Created by Matt on 2022-02-02.
//

import UIKit

internal class AppcuesPagingDotsTrait: ContainerDecoratingTrait {
    static let type = "@appcues/paging-dots"

    let style: ExperienceComponent.Style?

    var containerController: ExperienceContainerViewController?

    required init?(config: [String: Any]?) {
        self.style = config?["style", decodedAs: ExperienceComponent.Style.self]
    }

    func decorate(containerController: ExperienceContainerViewController) {
        let pageWrapView = UIView()
        pageWrapView.translatesAutoresizingMaskIntoConstraints = false
        pageWrapView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: style?.marginTop ?? 0,
            leading: style?.marginLeading ?? 0,
            bottom: style?.marginBottom ?? 0,
            trailing: style?.marginTrailing ?? 0)

        let pageControl = UIPageControl()
        pageControl.currentPageIndicatorTintColor = UIColor(dynamicColor: style?.foregroundColor) ?? .secondaryLabel
        pageControl.pageIndicatorTintColor = UIColor(dynamicColor: style?.backgroundColor) ?? .tertiaryLabel

        containerController.view.addSubview(pageWrapView)
        pageWrapView.addSubview(pageControl)

        pageControl.pin(to: pageWrapView.layoutMarginsGuide)

        var constraints: [NSLayoutConstraint] = []

        switch style?.verticalAlignment {
        case "top":
            constraints.append(pageWrapView.topAnchor.constraint(equalTo: containerController.view.safeAreaLayoutGuide.topAnchor))
        case "center":
            constraints.append(pageWrapView.centerYAnchor.constraint(equalTo: containerController.view.safeAreaLayoutGuide.centerYAnchor))
        default:
            constraints.append(pageWrapView.bottomAnchor.constraint(equalTo: containerController.view.safeAreaLayoutGuide.bottomAnchor))
        }

        switch style?.horizontalAlignment {
        case "leading":
            constraints.append(pageWrapView.leadingAnchor.constraint(equalTo: containerController.view.safeAreaLayoutGuide.leadingAnchor))
        case "trailing":
            constraints.append(pageWrapView.trailingAnchor.constraint(equalTo: containerController.view.safeAreaLayoutGuide.trailingAnchor))
        default:
            constraints.append(pageWrapView.centerXAnchor.constraint(equalTo: containerController.view.safeAreaLayoutGuide.centerXAnchor))
        }

        NSLayoutConstraint.activate(constraints)

        pageControl.addTarget(self, action: #selector(updateCurrentPage(sender:)), for: .valueChanged)

        containerController.pageMonitor.addObserver { newIndex, _ in
            pageControl.currentPage = newIndex
        }

        pageControl.numberOfPages = containerController.pageMonitor.numberOfPages
        pageControl.currentPage = containerController.pageMonitor.currentPage

        self.containerController = containerController
    }

    @objc
    func updateCurrentPage(sender: UIPageControl) {
        containerController?.navigate(to: sender.currentPage, animated: false)
    }
}
