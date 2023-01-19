//
//  DialogContainerView.swift
//  AppcuesKit
//
//  Created by James Ellis on 11/2/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class DialogContainerView: UIView {

    let dialogView: UIView = {
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

    init() {
        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(dialogView)

        NSLayoutConstraint.activate([
            // ensure the dialog can't exceed the container height (it should scroll instead).
            dialogView.topAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.topAnchor),
            dialogView.bottomAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.bottomAnchor),
            // this is required so the dialogView has an initial non-zero height, after which it can start sizing to the content.
            dialogView.layoutMarginsGuide.bottomAnchor.constraint(greaterThanOrEqualTo: dialogView.layoutMarginsGuide.topAnchor, constant: 1),
            dialogView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            dialogView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if let shadowLayer = shadowLayer {
            shadowLayer.path = UIBezierPath(roundedRect: dialogView.frame, cornerRadius: dialogView.layer.cornerRadius).cgPath
            shadowLayer.shadowPath = shadowLayer.path
        }
    }
}
