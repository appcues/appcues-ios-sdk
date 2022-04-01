//
//  DismissDropZoneView.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-25.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class DismissDropZoneView: UIView {

    /// Distance from the snapPoint at which the floating view locks to the snapPoint.
    let snapRange: CGFloat = 100

    var snapPoint: CGPoint { convert(imageView.center, to: superview) }

    lazy var imageView: UIImageView = {
        let image = UIImage(systemName: "xmark.circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 64))
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .white
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear

        addSubview(imageView)

        let nonSafeAreaHeight: CGFloat = 100

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            // vertically centered in the non-safe-area space
            imageView.centerYAnchor.constraint(equalTo: topAnchor, constant: nonSafeAreaHeight / 2),
            // set the height from the safe area
            topAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -nonSafeAreaHeight)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        let space = CGColorSpaceCreateDeviceRGB()
        let colors: [CGColor] = [
            UIColor(white: 0.1, alpha: 1.0).cgColor,
            UIColor(white: 0.0, alpha: 0.0).cgColor
        ]
        let locations: [CGFloat] = [0, 1]

        guard let gradient = CGGradient(colorsSpace: space, colors: colors as CFArray, locations: locations) else { return }

        let width = rect.width

        ctx.drawRadialGradient(
            gradient,
            startCenter: CGPoint(x: width / 2, y: width),
            startRadius: width / 2,
            endCenter: CGPoint(x: width / 2, y: width * 2),
            endRadius: width * 2,
            options: []
        )
    }

    func animateVisibility(visible isVisible: Bool, animated: Bool) {
        let animations: () -> Void = {
            self.alpha = isVisible ? 1 : 0
            self.imageView.transform = isVisible ? CGAffineTransform(scaleX: 1, y: 1) : CGAffineTransform(scaleX: 0.001, y: 0.001)
        }

        if animated {
            UIView.animate(
                withDuration: 0.3,
                animations: animations,
                completion: nil
            )
        } else {
            animations()
        }
    }
}
