//
//  ExperimentalConfettiTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-27.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit
import QuartzCore

@available(iOS 13.0, *)
internal class ExperimentalConfettiTrait: BackdropDecoratingTrait {
    static var type: String = "@experimental/confetti"

    private let style: ConfettiView.Style
    private let colors: [String]

    required init?(config: [String: Any]?) {
        style = ConfettiView.Style(rawValue: config?["style"] as? String ?? "") ?? .confetti
        colors = config?["colors", decodedAs: [String].self] ?? ["#5C5CFF", "#2CB4FF", "#20E0D6", "#FF5290"]
    }

    func decorate(backdropView: UIView) throws {
        let confettiView = ConfettiView(style: style, colors: colors)
        backdropView.addSubview(confettiView)
        confettiView.pin(to: backdropView)
        confettiView.start()
    }
}

// swiftlint:disable line_length force_unwrapping
@available(iOS 13.0, *)
private extension ExperimentalConfettiTrait {
    class ConfettiView: UIView {

        enum Style: String {
            case confetti
            case star
            case diamond
            case appcues

            var image: UIImage {
                let base64String: String

                switch self {
                case .confetti:
                    base64String = "iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAQAAACR313BAAAAbElEQVR42mNgIAf8d/gfgEtiwX8Q+IApJfB/wn8EcECXvPAfGUzAJ/n//wNk6QP/MYECTLIATeLD/4T/AgiDP6BIXoBLgaUbUCQPoHvoAbKDUHSCA+I/Tt+CpRG6F+AKygMoXsGixOB/AboYAN/oumhaUd9eAAAAAElFTkSuQmCC"
                case .star:
                    base64String = "iVBORw0KGgoAAAANSUhEUgAAAA8AAAAOCAYAAADwikbvAAAAqElEQVR4AWP4//8/LswIxL0gGpcafJrD/0NAOKmaOYD4PkgnlOYgRXPZf1RQRkizIhD7AXEdEH9E1gnl10Hl5ZE1dwPx+/8kAKj6bpBmESC+RIpOqHoRmJPFgfgWMbqg6sTR/SwDDln84AFIHa7QnkBA8wR8UbWBgOYN+DRfQFP8FY1/AZ/mD1BFJ4E4FIhZgDgEzIeAD7g0CwLxFiB2wJHqHKDyAjAxAMQZ0uwdEtwpAAAAAElFTkSuQmCC"
                case .diamond:
                    base64String = "iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAQAAACR313BAAAAbElEQVR42mNgIAf8d/gfgEtiwX8Q+IApJfB/wn8EcECXvPAfGUzAJ/n//wNk6QP/MYECTLIATeLD/4T/AgiDP6BIXoBLgaUbUCQPoHvoAbKDUHSCA+I/Tt+CpRG6F+AKygMoXsGixOB/AboYAN/oumhaUd9eAAAAAElFTkSuQmCC"
                case .appcues:
                     base64String = "iVBORw0KGgoAAAANSUhEUgAAAA4AAAASCAQAAADBVSe6AAAAcklEQVR42n3RSxGAMAxF0UhAQiUgIRKQgANwAI6QgAUcVEIlXBaFAtM+Jssz+Rsm4mBUtABrmyZQGEgKAxEUbqBwAYUDKHy6NbD7Q8Pb2FezFgwk/HOAgnkQv3LnL+ZSXjrvD95r+2ulgrHCu7T8p2HYCRi3Wo0eR4dlAAAAAElFTkSuQmCC"
                }

                return UIImage(data: Data(base64Encoded: base64String)!)!
            }
        }

        var style: Style
        var colors: [UIColor]

        var emitter: CAEmitterLayer?

        init(style: Style, colors: [String]) {
            self.style = style
            self.colors = colors.compactMap { UIColor(hex: $0) }
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSublayers(of layer: CALayer) {
            super.layoutSublayers(of: layer)
            emitter?.emitterPosition = CGPoint(x: bounds.width / 2.0, y: 0)
            emitter?.emitterSize = CGSize(width: bounds.width, height: 1)
        }

        func start() {
            let emitter = CAEmitterLayer()
            emitter.emitterShape = .line
            emitter.emitterPosition = CGPoint(x: bounds.width / 2.0, y: 0)
            emitter.emitterSize = CGSize(width: bounds.width, height: 1)
            emitter.emitterCells = colors.map { confettiCell(color: $0) }
            emitter.beginTime = CACurrentMediaTime()
            layer.addSublayer(emitter)

            self.emitter = emitter
        }

        func stop() {
            emitter?.removeFromSuperlayer()
            emitter = nil
        }

        private func confettiCell(color: UIColor) -> CAEmitterCell {
            let cell = CAEmitterCell()
            cell.contents = style.image.cgImage
            cell.color = color.cgColor
            cell.birthRate = 10
            cell.lifetime = 10
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 2
            cell.velocity = 360
            cell.velocityRange = 90
            cell.scaleRange = 1
            cell.scaleSpeed = -0.1
            cell.spin = 5
            cell.spinRange = 2
            return cell
        }
    }
}
