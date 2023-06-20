//
//  AppcuesPagingDotsTrait.swift
//  Appcues
//
//  Created by Matt on 2022-02-02.
//

import UIKit

@available(iOS 13.0, *)
internal class AppcuesPagingDotsTrait: AppcuesContainerDecoratingTrait {
    struct Config: Decodable {
        let style: ExperienceComponent.Style?
    }

    static let type = "@appcues/paging-dots"

    weak var metadataDelegate: AppcuesTraitMetadataDelegate?

    private let style: ExperienceComponent.Style?

    private weak var containerController: AppcuesExperienceContainerViewController?
    private weak var view: UIView?

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        let config = configuration.decode(Config.self)
        self.style = config?.style
    }

    func decorate(containerController: AppcuesExperienceContainerViewController) throws {
        guard containerController.pageMonitor.numberOfPages > 1 else { return }

        let pageWrapView = UIView()
        pageWrapView.translatesAutoresizingMaskIntoConstraints = false
        pageWrapView.directionalLayoutMargins = NSDirectionalEdgeInsets(marginFrom: style)

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
        self.view = pageWrapView
    }

    func undecorate(containerController: AppcuesExperienceContainerViewController) throws {
        view?.removeFromSuperview()
    }

    @objc
    func updateCurrentPage(sender: UIPageControl) {
        containerController?.navigate(to: sender.currentPage, animated: false)
    }
}
