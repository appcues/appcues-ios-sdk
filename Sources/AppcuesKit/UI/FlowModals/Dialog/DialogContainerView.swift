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
        view.backgroundColor = Asset.Color.dialogBackground.color
        view.alpha = 0.3
        return view
    }()

    let dialogView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 6.0
        view.clipsToBounds = true
        return view
    }()

    init() {
        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(backgroundView)
        addSubview(dialogView)

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

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
}
