//
//  ExperienceStepViewController.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

internal class ExperienceStepView: UIView {
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0

        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.isPagingEnabled = true
        view.showsHorizontalScrollIndicator = false

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

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // Ensure page cells resize when the controller size changes
        if let flowLayout = experienceStepView.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.invalidateLayout()
        }
    }

}

extension ExperienceStepViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        stepControllers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // swiftlint:disable:next force_cast
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StepPageCell.reuseID, for: indexPath) as! StepPageCell

        cell.setContent(to: stepControllers[indexPath.row].view)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // TODO: Step analytics here
        print("stepSeen \(indexPath.row)")
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // TODO: Step analytics here
        print("stepComplete \(indexPath.row)")
    }

    func collectionView(
        _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        view.frame.size
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
