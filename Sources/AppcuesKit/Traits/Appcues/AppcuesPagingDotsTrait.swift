//
//  AppcuesPagingDotsTrait.swift
//  Appcues
//
//  Created by Matt on 2022-02-02.
//

import UIKit

internal class AppcuesPagingDotsTrait: ContainerDecoratingTrait {
    static let type = "@appcues/paging-dots"

    let groupID: String?
    let style: ExperienceComponent.Style?

    var containerController: ExperienceStepContainer?

    required init?(config: [String: Any]?) {
        self.groupID = config?["groupID"] as? String
        self.style = config?["style", decodedAs: ExperienceComponent.Style.self]
    }

    func decorate(containerController: ExperienceStepContainer) {
        let pageControl = UIPageControl()
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.currentPageIndicatorTintColor = UIColor(dynamicColor: style?.foregroundColor) ?? .secondaryLabel
        pageControl.pageIndicatorTintColor = UIColor(dynamicColor: style?.backgroundColor) ?? .tertiaryLabel

        containerController.view.addSubview(pageControl)

        var constraints: [NSLayoutConstraint] = []

        switch style?.verticalAlignment {
        case "top":
            constraints.append(pageControl.topAnchor.constraint(equalTo: containerController.view.safeAreaLayoutGuide.topAnchor))
        case "center":
            constraints.append(pageControl.centerYAnchor.constraint(equalTo: containerController.view.safeAreaLayoutGuide.centerYAnchor))
        default:
            constraints.append(pageControl.bottomAnchor.constraint(equalTo: containerController.view.safeAreaLayoutGuide.bottomAnchor))
        }

        switch style?.horizontalAlignment {
        case "leading":
            constraints.append(pageControl.leadingAnchor.constraint(equalTo: containerController.view.safeAreaLayoutGuide.leadingAnchor))
        case "trailing":
            constraints.append(pageControl.trailingAnchor.constraint(equalTo: containerController.view.safeAreaLayoutGuide.trailingAnchor))
        default:
            constraints.append(pageControl.centerXAnchor.constraint(equalTo: containerController.view.safeAreaLayoutGuide.centerXAnchor))
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
