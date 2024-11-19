//
//  AnimatedImage.swift
//  AppcuesKit
//
//  Created by Matt on 2022-04-21.
//  Copyright © 2022 Appcues. All rights reserved.
//

import SwiftUI

internal struct AnimatedImage {
    let animatedImage: FLAnimatedImage
}

extension AnimatedImage: UIViewRepresentable {

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let animatedImageView = FLAnimatedImageView(animatedImage: animatedImage)
        animatedImageView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(animatedImageView)
        NSLayoutConstraint.activate([
            animatedImageView.widthAnchor.constraint(equalTo: view.widthAnchor),
            animatedImageView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // nothing to update, the content is constant
    }
}
