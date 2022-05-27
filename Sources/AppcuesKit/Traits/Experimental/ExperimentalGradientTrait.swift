//
//  ExperimentalGradientTrait.swift
//  Appcues
//
//  Created by Matt on 2022-01-28.
//

import UIKit

@available(iOS 13.0, *)
internal class ExperimentalGradientTrait: BackdropDecoratingTrait {
    static var type: String = "@experimental/gradient"

    private let colors: [String]

    required init?(config: [String: Any]?) {
        colors = config?["colors", decodedAs: [String].self] ?? ["#5C5CFF", "#2CB4FF", "#20E0D6", "#FF5290"]
    }

    func decorate(backdropView: UIView) throws {
        let gradientView = GradientView(colors: colors)
        backdropView.addSubview(gradientView)
        gradientView.pin(to: backdropView)
        gradientView.start()
    }
}

@available(iOS 13.0, *)
private extension ExperimentalGradientTrait {
    class GradientView: UIView {
        private let gradient = CAGradientLayer()
        var colorPairs: [[CGColor]]

        var colorIndex: Int = 0

        init(colors: [String]) {
            let mappedColors = colors.compactMap { UIColor(hex: $0)?.cgColor }
            let rotatedColors = Array(mappedColors.suffix(from: 1) + [mappedColors[0]])
            colorPairs = mappedColors.enumerated().map { idx, val in [val, rotatedColors[idx]] }

            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSublayers(of layer: CALayer) {
            super.layoutSublayers(of: layer)

            gradient.frame = bounds
        }

        func start() {
            layer.addSublayer(gradient)
            animateGradient()
        }

        func animateGradient() {
            gradient.colors = colorPairs[0]

            let gradientAnimation = CAKeyframeAnimation(keyPath: "colors")
            gradientAnimation.duration = 5.0
            gradientAnimation.repeatCount = .infinity
            gradientAnimation.values = colorPairs
            gradientAnimation.autoreverses = true
            gradientAnimation.fillMode = .forwards
            gradientAnimation.isRemovedOnCompletion = false

            gradient.add(gradientAnimation, forKey: "colors")
        }
    }
}
