//
//  ModalGroupViewController.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-15.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

/// Display a carousel of `ModalGroup.Step`'s.
internal class ModalGroupViewController: UIViewController {

    private let modalStepGroup: ModalGroup

    private let styleLoader: StyleLoading

    private lazy var modalGroupView = ModalGroupView()

    init(modalStepGroup: ModalGroup, styleLoader: StyleLoading) {
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
        modalGroupView.collectionView.dataSource = self
        setupFlow()
    }

    func closeModal() {
        dismiss(animated: true)
    }

    private func setupFlow() {
        if modalStepGroup.skippable {
            let button = modalGroupView.addDismissButton()
            button.addTarget(self, action: #selector(dismissButtonTapped(_:)), for: .touchUpInside)
        }
    }

    @objc
    private func dismissButtonTapped(_ sender: UIButton) {
        closeModal()
    }
}

extension ModalGroupViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        modalStepGroup.steps.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: WebWrapperCell.reuseID,
            for: indexPath) as? WebWrapperCell else { return UICollectionViewCell() }

        let modalStep = modalStepGroup.steps[indexPath.row]

        cell.render(
            html: modalStep.html,
            css: self.styleLoader.cachedStyles[self.modalStepGroup.styleID]?.globalStyling)
        return cell
    }
}
