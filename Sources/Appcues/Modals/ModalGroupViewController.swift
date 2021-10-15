//
//  ModalGroupViewController.swift
//  Appcues
//
//  Created by Matt on 2021-10-15.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

/// Display a carousel of `ModalGroup.Step`'s.
internal class ModalGroupViewController: UIViewController {

    private let modalStepGroup: ModalGroup

    private let styleLoader: StyleLoader

    private lazy var modalGroupView = ModalGroupView()

    private lazy var dataSource = setupDataSource()

    init(modalStepGroup: ModalGroup, styleLoader: StyleLoader) {
        self.modalStepGroup = modalStepGroup
        self.styleLoader = styleLoader

        super.init(nibName: nil, bundle: nil)

        // Customize the presentation style
        modalPresentationStyle = modalStepGroup.pattern.modalPresentationStyle
        if #available(iOS 15.0, *), modalStepGroup.pattern == .shorty, let sheet = sheetPresentationController {
            sheet.detents = [.medium(), .large()]
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = modalGroupView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        styleLoader.fetch(styleID: modalStepGroup.styleID) { [weak self] result in
            // Reload the whole collection so the successfully fetched CSS is applied
            if case .success = result {
                self?.modalGroupView.collectionView.reloadData()
            }
        }

        modalGroupView.collectionView.register(WebWrapperCell.self, forCellWithReuseIdentifier: WebWrapperCell.reuseID)

        setupFlow()
    }

    private func setupFlow() {
        var snapshot = NSDiffableDataSourceSnapshot<String, ModalGroup.Step>()
        snapshot.appendSections(["Steps"])
        snapshot.appendItems(modalStepGroup.steps)

        dataSource.apply(snapshot, animatingDifferences: false)

        if modalStepGroup.skippable {
            let button = modalGroupView.addDismissButton()
            button.addTarget(self, action: #selector(dismissButtonTapped(_:)), for: .touchUpInside)
        }
    }

    private func setupDataSource() -> UICollectionViewDiffableDataSource<String, ModalGroup.Step> {
        return UICollectionViewDiffableDataSource<String, ModalGroup.Step>(
            collectionView: modalGroupView.collectionView
        ) { (collectionView: UICollectionView, indexPath: IndexPath, identifier: ModalGroup.Step) -> UICollectionViewCell? in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: WebWrapperCell.reuseID,
                for: indexPath) as? WebWrapperCell else { return nil }

            cell.render(
                html: identifier.html,
                css: self.styleLoader.cachedStyles[self.modalStepGroup.styleID]?.globalStyling)
            return cell
        }
    }

    @objc
    private func dismissButtonTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
}
