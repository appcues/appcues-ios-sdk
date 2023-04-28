//
//  AppcuesBackdropKeyholeTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-12-07.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class AppcuesBackdropKeyholeTrait: AppcuesBackdropDecoratingTrait {
    struct Config: Decodable {
        let shape: String?
        let cornerRadius: Double?
        let blurRadius: Double?
        let spreadRadius: Double?
    }

    static let type: String = "@appcues/backdrop-keyhole"

    weak var metadataDelegate: AppcuesTraitMetadataDelegate?

    private let shape: KeyholeShape
    private let spreadRadius: CGFloat?

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        let config = configuration.decode(Config.self)

        self.shape = KeyholeShape(config?.shape, cornerRadius: config?.cornerRadius, blurRadius: config?.blurRadius)

        if let spreadRadius = config?.spreadRadius {
            self.spreadRadius = spreadRadius
        } else {
            self.spreadRadius = nil
        }
    }

    func decorate(backdropView: UIView) throws {
        guard let metadataDelegate = metadataDelegate else {
            // nothing to draw without a targetRectangle from the metadata dictionary
            backdropView.layer.mask = nil
            return
        }

        metadataDelegate.set([
            "keyholeShape": shape,
            "keyholeSpread": spreadRadius
        ])

        metadataDelegate.registerHandler(for: Self.type, animating: false) { [weak self] in
            self?.handle(backdropView: backdropView, metadata: $0)
        }
    }

    func undecorate(backdropView: UIView) throws {
        guard let metadataDelegate = metadataDelegate else {
            backdropView.layer.mask = nil
            return
        }

        metadataDelegate.unset(keys: [ "keyholeShape", "keyholeSpread" ])
    }

    // swiftlint:disable:next function_body_length
    private func handle(backdropView: UIView, metadata: AppcuesTraitMetadata) {
        guard backdropView.bounds != .zero else { return }

        let newMaskPath = UIBezierPath(rect: backdropView.bounds)
        let newShape: KeyholeShape = metadata["keyholeShape"] ?? metadata[previous: "keyholeShape"] ?? .circle(blurRadius: 0)
        let targetRectangle: CGRect = {
            if let newTarget: CGRect = metadata["targetRectangle"] {
                return newTarget.spread(by: metadata["keyholeSpread"])
            } else if let oldTarget: CGRect = metadata[previous: "targetRectangle"] {
                // If no new targetRectangle, we want to remove the keyhole with a scaling down animation,
                // so take the previous value scaled down to zero
                return oldTarget.zeroed
            } else {
                return .zero
            }
        }()
        let newKeyholeBezierPath = newShape.path(for: targetRectangle)
        newMaskPath.append(newKeyholeBezierPath)

        let oldMaskPath = UIBezierPath(rect: backdropView.bounds)
        let oldShape: KeyholeShape = metadata[previous: "keyholeShape"] ?? metadata["keyholeShape"] ?? .circle(blurRadius: 0)
        let oldTargetRectangle: CGRect = {
            if let oldTarget: CGRect = metadata[previous: "targetRectangle"] {
                return oldTarget.spread(by: metadata[previous: "keyholeSpread"])
            } else if let newTarget: CGRect = metadata["targetRectangle"] {
                // If no old targetRectangle, we want to add the keyhole with a scaling up animation,
                // so take the new value scaled down to zero
                return newTarget.zeroed
            } else {
                return .zero
            }
        }()
        let oldKeyholeBezierPath = oldShape.path(for: oldTargetRectangle)
        oldMaskPath.append(oldKeyholeBezierPath)

        let maskLayer: CALayer

        if case let .circle(blurRadius: newBlurRadius) = newShape {
            let newStartPoint = CGPoint(
                x: newKeyholeBezierPath.bounds.midX,
                y: newKeyholeBezierPath.bounds.midY
            )
            let newEndPoint = CGPoint(
                x: newKeyholeBezierPath.bounds.maxX + newBlurRadius,
                y: newKeyholeBezierPath.bounds.maxY + newBlurRadius
            )

            // Start the gradient at the edge of the keyhole path.
            // Doesn't matter whether we use x or y since it's a circle.
            let newStartLocation: Double
            // Avoid a potential division by zero. If the start and end are the same, the gradient is irrelevant anyways.
            if newEndPoint.x != newStartPoint.x {
                // Cap at 0.995 so we don't collide with the end location.
                newStartLocation = min(
                    0.995,
                    (newEndPoint.x - newBlurRadius - newStartPoint.x) / (newEndPoint.x - newStartPoint.x)
                )
            } else {
                newStartLocation = 0
            }

            let gradientMaskLayer = CAGradientLayer()
            gradientMaskLayer.frame = backdropView.bounds
            gradientMaskLayer.type = .radial
            gradientMaskLayer.colors = [UIColor.clear.cgColor, UIColor.white.cgColor]
            // swiftlint:disable:next legacy_objc_type
            gradientMaskLayer.locations = [NSNumber(value: newStartLocation), 1.0]
            gradientMaskLayer.startPoint = newStartPoint.relative(in: backdropView.bounds.size)
            gradientMaskLayer.endPoint = newEndPoint.relative(in: backdropView.bounds.size)

            if let animationGroup = metadata.animationGroup() {
                let oldBlurRadius: CGFloat = {
                    if case let .circle(blurRadius: blurRadius) = oldShape {
                        return blurRadius
                    } else {
                        return 0
                    }
                }()
                let oldStartPoint = CGPoint(
                    x: oldKeyholeBezierPath.bounds.midX,
                    y: oldKeyholeBezierPath.bounds.midY
                )
                let oldEndPoint = CGPoint(
                    x: oldKeyholeBezierPath.bounds.maxX + oldBlurRadius,
                    y: oldKeyholeBezierPath.bounds.maxY + oldBlurRadius
                )
                let oldStartLocation: Double
                if newEndPoint.x != newStartPoint.x {
                    oldStartLocation = min(
                        0.995,
                        (oldEndPoint.x - oldBlurRadius - oldStartPoint.x) / (oldEndPoint.x - oldStartPoint.x)
                    )
                } else {
                    oldStartLocation = 0
                }

                let locationsAnimation = CABasicAnimation(keyPath: "locations")
                // swiftlint:disable:next legacy_objc_type
                locationsAnimation.fromValue = [NSNumber(value: oldStartLocation), 1.0]
                locationsAnimation.toValue = gradientMaskLayer.locations

                let startPointAnimation = CABasicAnimation(keyPath: "startPoint")
                startPointAnimation.fromValue = oldStartPoint.relative(in: backdropView.bounds.size)
                startPointAnimation.toValue = gradientMaskLayer.startPoint

                let endPointAnimation = CABasicAnimation(keyPath: "endPoint")
                endPointAnimation.fromValue = oldEndPoint.relative(in: backdropView.bounds.size)
                endPointAnimation.toValue = gradientMaskLayer.endPoint

                animationGroup.animations = [locationsAnimation, startPointAnimation, endPointAnimation]
                gradientMaskLayer.add(animationGroup, forKey: nil)
            }

            maskLayer = gradientMaskLayer
        } else {
            let shapeMaskLayer = CAShapeLayer()
            shapeMaskLayer.fillRule = .evenOdd
            shapeMaskLayer.path = newMaskPath.cgPath

            if let animationGroup = metadata.animationGroup() {
                let pathAnimation = CABasicAnimation(keyPath: "path")
                pathAnimation.fromValue = oldMaskPath.cgPath
                pathAnimation.toValue = newMaskPath.cgPath

                animationGroup.animations = [pathAnimation]
                shapeMaskLayer.add(animationGroup, forKey: nil)
            }

            maskLayer = shapeMaskLayer
        }

        // https://stackoverflow.com/a/36461202
        // update the path property on the mask layer, using a CATransaction to prevent an implicit animation
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        backdropView.layer.mask = maskLayer
        CATransaction.commit()
    }
}

@available(iOS 13.0, *)
extension AppcuesBackdropKeyholeTrait {
    enum KeyholeShape {
        case rectangle(cornerRadius: CGFloat)
        case circle(blurRadius: CGFloat)

        init(_ shape: String?, cornerRadius: Double? = nil, blurRadius: Double? = nil) {
            switch shape {
            case "circle":
                self = .circle(blurRadius: blurRadius ?? 0)
            default:
                // fallback to a tiny value instead of 0 so the path can animate nicely to other values
                self = .rectangle(cornerRadius: cornerRadius ?? .leastNonzeroMagnitude)
            }
        }

        func path(for rect: CGRect, includeBlur: Bool = false) -> UIBezierPath {
            switch self {
            case .rectangle(let cornerRadius):
                return UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
            case .circle(let blurRadius):
                // A circle that fully encompasses the target rectangle
                let radius = sqrt(pow(rect.width, 2) + pow(rect.height, 2)) / 2 + (includeBlur ? blurRadius : 0)
                let rect = CGRect(
                    x: rect.midX - radius,
                    y: rect.midY - radius,
                    width: radius * 2,
                    height: radius * 2
                )
                return UIBezierPath(roundedRect: rect, cornerRadius: radius)
            }
        }
    }
}
