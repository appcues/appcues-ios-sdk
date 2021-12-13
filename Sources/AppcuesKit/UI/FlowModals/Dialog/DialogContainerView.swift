//
//  DialogContainerView.swift
//  AppcuesKit
//
//  Created by James Ellis on 11/2/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

internal class DialogContainerView: UIView {

    let backgroundView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let dialogView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
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

        addSubview(backgroundView)
        addSubview(dialogView)
        backgroundView.pin(to: self)

        NSLayoutConstraint.activate([
            dialogView.centerYAnchor.constraint(equalTo: centerYAnchor),
            dialogView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5),
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
