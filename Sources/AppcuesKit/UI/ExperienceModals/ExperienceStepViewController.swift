//
//  ExperienceStepViewController.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

internal class ExperienceStepView: UIView {

    lazy var preferredHeightConstraint: NSLayoutConstraint = {
        var constraint = heightAnchor.constraint(equalToConstant: 0)
        constraint.priority = .defaultLow
        constraint.isActive = true
        return constraint
    }()

    var scrollHandler: NSCollectionLayoutSectionVisibleItemsInvalidationHandler?

    lazy var collectionView: UICollectionView = {
        let section = NSCollectionLayoutSection.fullPaged
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

        // TODO: Paging dots if multiple pages and if swipeEnabled 
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// TODO: This controller will be renamed (ExperienceStepGroupVC?) with the modal group trait.
internal class ExperienceStepViewController: UIViewController {

    let viewModel: ExperienceStepViewModel

    weak var lifecycleHandler: ExperienceStepLifecycleHandler?

    private lazy var experienceStepView = ExperienceStepView()

    let stepControllers: [UIViewController]

    init(viewModel: ExperienceStepViewModel) {
        self.viewModel = viewModel

        // TODO: This is temporary until the new step and modal group trait is implemented.
        // The controllers will be created in the ExperienceStateMachine and passed into this init.
        let pages: [ExperienceComponent]
        switch viewModel.step.content {
        case .pager(let pagerModel):
            pages = pagerModel.items
        default:
            pages = [viewModel.step.content]
        }

        stepControllers = pages.map { page in
            let rootView = ExperienceStepRootView(rootView: page.view, viewModel: viewModel)
            let contentViewController = AppcuesHostingController(rootView: rootView)
            contentViewController.view.backgroundColor = .clear
            return contentViewController
        }

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = experienceStepView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        stepControllers.forEach {
            addChild($0)
            $0.didMove(toParent: self)
        }

        experienceStepView.scrollHandler = { [weak self] visibleItems, point, environment in
            self?.scrollHandler(visibleItems, point, environment)
        }

        experienceStepView.collectionView.register(StepPageCell.self, forCellWithReuseIdentifier: StepPageCell.reuseID)
        experienceStepView.collectionView.dataSource = self
        experienceStepView.collectionView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lifecycleHandler?.stepWillAppear()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        lifecycleHandler?.stepDidAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        lifecycleHandler?.stepWillDisappear()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        lifecycleHandler?.stepDidDisappear()
    }

    func goTo(pageIndex: Int) {
        experienceStepView.collectionView.scrollToItem(at: IndexPath(row: pageIndex, section: 0), at: .centeredHorizontally, animated: true)
    }

    func scrollHandler(_ visibleItems: [NSCollectionLayoutVisibleItem], _ point: CGPoint, _ environment: NSCollectionLayoutEnvironment) {
        // Visible items always contains index 0, even when it shouldn't, so filter out pages that aren't actually visible.
        let width = environment.container.contentSize.width
        let visibleRange = (point.x - width + CGFloat.leastNormalMagnitude)..<(point.x + width)
        let actuallyVisibleItems = visibleItems.filter { visibleRange.contains(CGFloat($0.indexPath.row) * width) }

        let cells: [StepPageCell] = actuallyVisibleItems
            .compactMap { experienceStepView.collectionView.cellForItem(at: $0.indexPath) as? StepPageCell }

        guard cells.count == 2 else {
            // The magic value 17 is needed for the initial sizing pass.
            // Any value smaller doesn't work (but larger ones are fine).
            experienceStepView.preferredHeightConstraint.constant = cells.last?.contentHeight ?? 17

            if let stepIndex = visibleItems.last?.indexPath.row {
                // TODO: use this for step seen analytics
                print("current step index", stepIndex)
            }
            return
        }

        // For a contentHeight value large enough to scroll, this can create a slightly odd animation where the container
        // reaches it's max size too quickly because we're scaling the size as if the full contentHeight can be achieved.
        // TODO: To fix, we'd need to cap the contentHeight values at the max height of the container.
        if let firstHeight = cells[0].contentHeight, let secondHeight = cells[1].contentHeight {
            let heightDiff = secondHeight - firstHeight
            let transitionPercentage = transitionPercentage(itemWidth: width, xOffset: point.x)
            experienceStepView.preferredHeightConstraint.constant = firstHeight + heightDiff * transitionPercentage
        }
    }

    private func transitionPercentage(itemWidth: CGFloat, xOffset: CGFloat) -> CGFloat {
        var percentage = (xOffset.truncatingRemainder(dividingBy: itemWidth)) / itemWidth
        // When the scroll percentage hits exactly 100, it's actually calculated as 0 from the mod operator, so set it to 1
        if percentage == 0 {
            percentage = 1
        }
        return percentage
    }
}

extension ExperienceStepViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        stepControllers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // swiftlint:disable:next force_cast
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StepPageCell.reuseID, for: indexPath) as! StepPageCell

        cell.setContent(to: stepControllers[indexPath.row].view)

        return cell
    }
}

extension ExperienceStepViewController {
    class StepPageCell: UICollectionViewCell {
        static var reuseID: String { String(describing: self) }

        private lazy var scrollView: UIScrollView = {
            let view = UIScrollView()
            // Force a consistent safe area behaviour regardless of whether the content scrolls
            view.contentInsetAdjustmentBehavior = .always
            return view
        }()

        var contentHeight: CGFloat? {
            scrollView.subviews.first?.frame.size.height
        }

        override init(frame: CGRect) {
            super.init(frame: .zero)

            contentView.addSubview(scrollView)
            scrollView.pin(to: contentView)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            // reset the contentOffset so each cell starts at the top
            scrollView.contentOffset = .zero
            scrollView.subviews.forEach { $0.removeFromSuperview() }
        }

        func setContent(to view: UIView) {
            scrollView.subviews.forEach { $0.removeFromSuperview() }

            scrollView.addSubview(view)
            view.pin(to: scrollView)
            NSLayoutConstraint.activate([
                view.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
            ])
        }
    }
}
