//
//  AppcuesCarouselTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-12.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal struct AppcuesCarouselTrait: ContainerCreatingTrait {
    static let type = "@appcues/carousel"

    init?(config: [String: Any]?) {
    }

    func createContainer(for stepControllers: [UIViewController], targetPageIndex: Int) throws -> ExperienceContainerViewController {
        CarouselContainerViewController(stepControllers: stepControllers, targetPageIndex: targetPageIndex)
    }
}

@available(iOS 13.0, *)
extension AppcuesCarouselTrait {

    class CarouselContainerViewController: UIViewController, ExperienceContainerViewController,
                                           UICollectionViewDataSource, UICollectionViewDelegate {

        weak var lifecycleHandler: ExperienceContainerLifecycleHandler?
        let pageMonitor: PageMonitor

        var targetPageIndex: Int?

        private lazy var carouselView = ExperienceCarouselView()

        private let stepControllers: [UIViewController]

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

        override func loadView() {
            view = carouselView
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            carouselView.scrollHandler = { [weak self] visibleItems, point, environment in
                self?.scrollHandler(visibleItems, point, environment)
            }

            carouselView.collectionView.register(StepPageCell.self, forCellWithReuseIdentifier: StepPageCell.reuseID)
            carouselView.collectionView.dataSource = self
            carouselView.collectionView.delegate = self
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            lifecycleHandler?.containerWillAppear()

            if let pageIndex = targetPageIndex {
                targetPageIndex = nil
                DispatchQueue.main.async {
                    self.navigate(to: pageIndex, animated: false)
                }
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
            carouselView.preferredHeightConstraint.constant = container.preferredContentSize.height
            preferredContentSize = container.preferredContentSize
        }

        func navigate(to pageIndex: Int, animated: Bool) {
            carouselView.collectionView.scrollToItem(
                at: IndexPath(row: pageIndex, section: 0),
                at: .centeredHorizontally,
                animated: animated)
        }

        func scrollHandler(
            _ visibleItems: [NSCollectionLayoutVisibleItem], _ point: CGPoint, _ environment: NSCollectionLayoutEnvironment
        ) {
            let width = environment.container.contentSize.width

            // Visible items always contains index 0, even when it shouldn't, so filter out pages that aren't actually visible.
            // `collectionView.indexPathsForVisibleItems` would be an option but it's not always correct when jumping without animation.
            let visibleRange = (point.x - width + CGFloat.leastNormalMagnitude)..<(point.x + width)
            let actuallyVisibleItems = visibleItems.filter { visibleRange.contains(CGFloat($0.indexPath.row) * width) }

            let heights: [CGFloat] = actuallyVisibleItems
                .map { stepControllers[$0.indexPath.row].preferredContentSize.height }

            if heights.count == 2 {
                // For a contentHeight value large enough to scroll, this can create a slightly odd animation where the container
                // reaches it's max size too quickly because we're scaling the size as if the full contentHeight can be achieved.
                // TODO: To fix, we'd need to cap the contentHeight values at the max height of the container.
                let heightDiff = heights[1] - heights[0]
                let transitionPercentage = transitionPercentage(itemWidth: width, xOffset: point.x)
                // Set the preferred container height to transition smoothly between the difference in heights.
                carouselView.preferredHeightConstraint.constant = heights[0] + heightDiff * transitionPercentage
            } else {
                if let singleHeight = heights.last {
                    carouselView.preferredHeightConstraint.constant = singleHeight
                }

                if let pageIndex = visibleItems.last?.indexPath.row {
                    pageMonitor.set(currentPage: pageIndex)
                }
            }
        }

        /// Calculate the horizontal scroll progress between any two sibling pages.
        private func transitionPercentage(itemWidth: CGFloat, xOffset: CGFloat) -> CGFloat {
            var percentage = (xOffset.truncatingRemainder(dividingBy: itemWidth)) / itemWidth
            // When the scroll percentage hits exactly 100, it's actually calculated as 0 from the mod operator, so set it to 1
            if percentage == 0 {
                percentage = 1
            }
            return percentage
        }

        // - MARK: UICollectionViewDataSource, UICollectionViewDelegate

        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            stepControllers.count
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StepPageCell.reuseID, for: indexPath)

            if let pageCell = cell as? StepPageCell {
                pageCell.setContent(to: stepControllers[indexPath.row].view)
            }

            return cell
        }

        func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
            let controller = stepControllers[indexPath.row]
            addChild(controller)
            controller.didMove(toParent: self)
        }

        func collectionView(
            _ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath
        ) {
            let controller = stepControllers[indexPath.row]
            controller.willMove(toParent: nil)
            controller.removeFromParent()
        }
    }

    class ExperienceCarouselView: UIView {

        lazy var preferredHeightConstraint: NSLayoutConstraint = {
            var constraint = heightAnchor.constraint(equalToConstant: 0)
            constraint.priority = .defaultLow
            constraint.isActive = true
            return constraint
        }()

        var scrollHandler: NSCollectionLayoutSectionVisibleItemsInvalidationHandler?

        lazy var collectionView: UICollectionView = {
            let section = NSCollectionLayoutSection.fullScreenCarousel()
            section.visibleItemsInvalidationHandler = { [weak self] visibleItems, point, environment in
                self?.scrollHandler?(visibleItems, point, environment)
            }

            let layout = UICollectionViewCompositionalLayout(section: section)

            let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
            view.backgroundColor = .clear
            view.alwaysBounceVertical = false
            view.contentInsetAdjustmentBehavior = .never

            return view
        }()

        init() {
            super.init(frame: .zero)

            addSubview(collectionView)
            collectionView.pin(to: self)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    class StepPageCell: UICollectionViewCell {

        override init(frame: CGRect) {
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            contentView.subviews.forEach { $0.removeFromSuperview() }
        }

        func setContent(to view: UIView) {
            contentView.addSubview(view)
            view.pin(to: contentView)
        }
    }
}
