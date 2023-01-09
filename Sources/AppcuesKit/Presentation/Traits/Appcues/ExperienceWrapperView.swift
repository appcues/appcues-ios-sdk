//
//  ExperienceWrapperView.swift
//  AppcuesKit
//
//  Created by James Ellis on 11/2/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class ExperienceWrapperView: UIView {

    var preferredContentSize: CGSize?

    let contentWrapperView: UIView = {
        let view = UIView(frame: .zero)
        view.clipsToBounds = true
        view.layoutMargins = .zero
        return view
    }()

    let shadowWrappingView = UIView()

    required init() {
        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(shadowWrappingView)
        shadowWrappingView.addSubview(contentWrapperView)
        positionContentView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func positionContentView() {
        contentWrapperView.pin(to: shadowWrappingView)

        contentWrapperView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // this is required so the dialogView has an initial non-zero height, after which it can start sizing to the content.
            contentWrapperView.layoutMarginsGuide.bottomAnchor.constraint(
                greaterThanOrEqualTo: contentWrapperView.layoutMarginsGuide.topAnchor,
                constant: 1),

            contentWrapperView.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentWrapperView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            contentWrapperView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),

            // ensure the dialog can't exceed the container height (it should scroll instead).
            contentWrapperView.topAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.topAnchor),
            contentWrapperView.bottomAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    func applyCornerRadius(_ cornerRadius: CGFloat?) {
        contentWrapperView.layer.cornerRadius = cornerRadius ?? 0
    }

    func applyBorder(color: UIColor?, width: CGFloat?) {
        guard let color = color, let width = width else { return }

        contentWrapperView.layer.borderColor = color.cgColor
        contentWrapperView.layer.borderWidth = width
        contentWrapperView.layoutMargins = UIEdgeInsets(top: width, left: width, bottom: width, right: width)
    }
}
