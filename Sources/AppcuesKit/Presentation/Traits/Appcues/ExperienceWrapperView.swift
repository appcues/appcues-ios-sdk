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

    let contentWrapperView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        view.layoutMargins = .zero
        return view
    }()

    var shadowLayer: CAShapeLayer? {
        willSet {
            // remove existing
            shadowLayer?.removeFromSuperlayer()
        }
        didSet {
            if let shadowLayer = shadowLayer {
                layer.insertSublayer(shadowLayer, at: 0)
            }
        }
    }

    required init() {
        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(contentWrapperView)
        positionContentWrapperView()

        NSLayoutConstraint.activate([
            // this is required so the dialogView has an initial non-zero height, after which it can start sizing to the content.
            contentWrapperView.layoutMarginsGuide.bottomAnchor.constraint(
                greaterThanOrEqualTo: contentWrapperView.layoutMarginsGuide.topAnchor,
                constant: 1)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if let shadowLayer = shadowLayer {
            shadowLayer.path = UIBezierPath(
                roundedRect: contentWrapperView.frame,
                cornerRadius: contentWrapperView.layer.cornerRadius
            ).cgPath
            shadowLayer.shadowPath = shadowLayer.path
        }
    }

    func positionContentWrapperView() {
        NSLayoutConstraint.activate([
            contentWrapperView.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentWrapperView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            contentWrapperView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),

            // ensure the dialog can't exceed the container height (it should scroll instead).
            contentWrapperView.topAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.topAnchor),
            contentWrapperView.bottomAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.bottomAnchor),
        ])
    }
}
