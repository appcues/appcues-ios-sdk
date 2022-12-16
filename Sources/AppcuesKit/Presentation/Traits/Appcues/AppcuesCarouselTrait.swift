//
//  AppcuesCarouselTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-12.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class AppcuesCarouselTrait: ContainerCreatingTrait {
    static let type = "@appcues/carousel"

    weak var metadataDelegate: TraitMetadataDelegate?

    required init?(configuration: ExperiencePluginConfiguration, level: ExperienceTraitLevel) {
    }

    func createContainer(for stepControllers: [UIViewController], with pageMonitor: PageMonitor) throws -> ExperienceContainerViewController {
        CarouselContainerViewController(stepControllers: stepControllers, pageMonitor: pageMonitor)
    }
}

@available(iOS 13.0, *)
extension AppcuesCarouselTrait {

    class CarouselContainerViewController: ExperienceContainerViewController, UICollectionViewDataSource, UICollectionViewDelegate {

        weak var lifecycleHandler: ExperienceContainerLifecycleHandler?
        let pageMonitor: PageMonitor

        private lazy var carouselView = ExperienceCarouselView()

        private let stepControllers: [UIViewController]

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

        override func loadView() {
            view = carouselView
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            carouselView.collectionView.register(StepPageCell.self, forCellWithReuseIdentifier: StepPageCell.reuseID)
            carouselView.collectionView.dataSource = self
            carouselView.collectionView.delegate = self
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

            // If the current child controller changes it's preferred size, propagate that to the paging view.
            carouselView.preferredHeightConstraint.constant = container.preferredContentSize.height
            preferredContentSize = container.preferredContentSize
        }

        override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
            // Use the currentPage value instead of collectionView.indexPathsForVisibleItems because
            // that occasionally includes additional items.
            let targetIndex = IndexPath(item: pageMonitor.currentPage, section: 0)

            // Using `coordinator.animate` would be ideal, and it does work,
            // but that animation is jankier when going from landscape to portrait.
            DispatchQueue.main.async {
                self.carouselView.collectionView.scrollToItem(at: targetIndex, at: .centeredHorizontally, animated: false)
            }

            super.viewWillTransition(to: size, with: coordinator)
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
            // Need to wait for collectionView layout to complete before we can properly scroll to the correct initial item,
            // so viewWillAppear is too early (unless we `DispatchQueue.main.async`) and viewDidAppear is too late.
            // The nil check ensures this will only run on the first cell display.
            if carouselView.scrollHandler == nil {
                navigate(to: pageMonitor.currentPage, animated: false)

                // Add scroll handler which tracks step progress after the correct initial step is set
                carouselView.scrollHandler = { [weak self] visibleItems, point, environment in
                    self?.scrollHandler(visibleItems, point, environment)
                }
            }

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
            view.translatesAutoresizingMaskIntoConstraints = false
            view.alwaysBounceVertical = false
            view.contentInsetAdjustmentBehavior = .never
            view.backgroundColor = .clear

            return view
        }()

        init() {
            super.init(frame: .zero)

            addSubview(collectionView)
            NSLayoutConstraint.activate([
                collectionView.topAnchor.constraint(equalTo: topAnchor),
                collectionView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
                collectionView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
                collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
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
