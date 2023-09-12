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

    let backdropView = UIView()

    let contentWrapperView: UIView = {
        // contentWrapperView can take a tooltip shape mask, so ignore hits outside that shape when it's set.
        let view = HitTestingOverrideUIView(overrideApproach: .applyMask)
        view.clipsToBounds = true
        view.layoutMargins = .zero
        return view
    }()

    // shadowWrappingView wraps contentWrapperView, so ignore hits that aren't specifically on contentWrapperView.
    let shadowWrappingView: UIView = HitTestingOverrideUIView(overrideApproach: .ignoreSelf)

    required init() {
        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(backdropView)
        backdropView.pin(to: self)

        addSubview(shadowWrappingView)
        shadowWrappingView.addSubview(contentWrapperView)
        positionContentView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func positionContentView() {
        shadowWrappingView.translatesAutoresizingMaskIntoConstraints = false

        contentWrapperView.pin(to: shadowWrappingView)

        NSLayoutConstraint.activate([
            contentWrapperView.leadingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor),
            contentWrapperView.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor),
            contentWrapperView.widthAnchor.constraint(lessThanOrEqualTo: readableContentGuide.widthAnchor),

            // ensure the dialog can't exceed the container height (it should scroll instead).
            contentWrapperView.topAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.topAnchor),
            contentWrapperView.bottomAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.bottomAnchor)
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
