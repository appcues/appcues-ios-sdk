//
//  AppcuesEffectsTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2024-07-04.
//  Copyright © 2024 Appcues. All rights reserved.
//

import UIKit
import QuartzCore

internal class AppcuesEffectsTrait: AppcuesBackdropDecoratingTrait {
    static let type: String = "@appcues/effects"

    var metadataDelegate: AppcuesTraitMetadataDelegate?

    private let config: Config

    private var effectView: UIView?

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        guard let config = configuration.decode(Config.self) else { return nil }
        self.config = config
    }

    @MainActor
    func decorate(backdropView: UIView) async throws {
        let effectView: UIView
        switch config.presentationStyle {
        case .confetti:
            let confettiView = ConfettiView(config: config)
            confettiView.start()
            effectView = confettiView
        }

        effectView.isUserInteractionEnabled = false
        backdropView.addSubview(effectView)
        effectView.pin(to: backdropView)
        self.effectView = effectView
    }

    @MainActor
    func undecorate(backdropView: UIView) throws {
        effectView?.removeFromSuperview()
        effectView = nil
    }
}

private extension AppcuesEffectsTrait {
    enum PresentationStyle: String, Decodable {
        case confetti
    }

    struct EffectStyle: Decodable {
        let colors: [String]?
    }

    struct Config: Decodable {
        let presentationStyle: PresentationStyle
        let duration: Int
        let intensity: Double
        let style: EffectStyle

        enum CodingKeys: CodingKey {
            case presentationStyle
            case duration
            case intensity
            case style
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            self.presentationStyle = try container.decode(PresentationStyle.self, forKey: .presentationStyle)
            self.duration = (try container.decodeIfPresent(Int.self, forKey: .duration)) ?? 2_000
            self.intensity = (try container.decodeIfPresent(Double.self, forKey: .intensity)) ?? 1
            self.style = (try container.decodeIfPresent(EffectStyle.self, forKey: .style)) ?? EffectStyle(colors: nil)
        }
    }

    class ConfettiView: UIView {
        enum ConfettiShape: CaseIterable {
            case square
            case rectangle
            case circle

            func image() -> UIImage? {
                let imageRect: CGRect = {
                    switch self {
                    case .square:
                        return CGRect(x: 0, y: 0, width: 10, height: 10)
                    case .rectangle:
                        return CGRect(x: 0, y: 0, width: 12, height: 7)
                    case .circle:
                        return CGRect(x: 0, y: 0, width: 10, height: 10)
                    }
                }()

                UIGraphicsBeginImageContext(imageRect.size)
                defer {
                    UIGraphicsEndImageContext()
                }

                guard let context = UIGraphicsGetCurrentContext() else { return nil }
                context.setFillColor(UIColor.white.cgColor)

                switch self {
                case .square, .rectangle:
                    context.fill(imageRect)
                case .circle:
                    context.fillEllipse(in: imageRect)
                }

                return UIGraphicsGetImageFromCurrentImageContext()
            }
        }

        let duration: CFTimeInterval
        let intensity: Double
        let colors: [UIColor]

        lazy var emitter: CAEmitterLayer = {
            let emitter = CAEmitterLayer()
            emitter.emitterShape = .line
            emitter.beginTime = CACurrentMediaTime()
            return emitter
        }()

        init(config: Config) {
            self.duration = Double(config.duration) / 1_000
            self.intensity = config.intensity
            self.colors = (config.style.colors ?? ["#5C5CFF", "#20E0D6", "#FF5290"]).compactMap { UIColor(hex: $0) }
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSublayers(of layer: CALayer) {
            super.layoutSublayers(of: layer)
            emitter.emitterPosition = CGPoint(x: bounds.midX, y: bounds.minY)
            emitter.emitterSize = CGSize(width: bounds.width, height: 0)
        }

        func start() {
            emitter.emitterCells = ConfettiShape.allCases
                .compactMap { $0.image() }
                .flatMap { image in
                    colors.map { color in
                        confettiCell(contents: image, color: color)
                    }
                }
            layer.addSublayer(emitter)

            // Birth many particles at the start to get things going and then taper off
            let animation = CAKeyframeAnimation(keyPath: #keyPath(CAEmitterLayer.birthRate))
            animation.duration = duration
            animation.timingFunction = CAMediaTimingFunction(name: .easeIn)
            animation.values = [2, 1, 1, 0].map { $0 * intensity }
            animation.keyTimes = [0, 0.2, 0.8, 1]
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false

            emitter.add(animation, forKey: nil)
        }

        func stop() {
            emitter.removeFromSuperlayer()
        }

        private func confettiCell(contents: UIImage, color: UIColor) -> CAEmitterCell {
            let cell = CAEmitterCell()
            cell.contents = contents.cgImage
            cell.color = color.cgColor
            cell.beginTime = 0.1

            // These values are all magic numbers that make it look "right"
            cell.birthRate = 20
            cell.lifetime = 10
            cell.emissionLongitude = .pi // Direct particles downwards
            cell.emissionRange = .pi / 6
            cell.velocity = 150
            cell.velocityRange = 100
            cell.yAcceleration = 40
            cell.spin = 12
            cell.spinRange = 4
            cell.scaleRange = 0.5

            // Make particle spin on multiple axes
            cell.setValue("plane", forKey: "particleType")
            cell.setValue(CGFloat.pi, forKey: "orientationRange")
            cell.setValue(CGFloat.pi / 2, forKey: "orientationLongitude")
            cell.setValue(CGFloat.pi / 2, forKey: "orientationLatitude")

            return cell
        }
    }
}
