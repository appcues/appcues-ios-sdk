//
//  AppcuesBackdropKeyholeTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-12-07.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class AppcuesBackdropKeyholeTrait: BackdropDecoratingTrait {
    struct Config: Decodable {
        let shape: String
        let cornerRadius: Double?
        let spreadRadius: Double?
    }
    static let type: String = "@appcues/backdrop-keyhole"

    weak var metadataDelegate: TraitMetadataDelegate?

    private let shape: KeyholeShape
    private let spreadRadius: CGFloat?

    required init?(configuration: ExperiencePluginConfiguration, level: ExperienceTraitLevel) {
        guard let config = configuration.decode(Config.self),
              let keyholeShape = KeyholeShape(config.shape, cornerRadius: config.cornerRadius) else {
            return nil
        }

        self.shape = keyholeShape

        if let spreadRadius = config.spreadRadius {
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

    private func handle(backdropView: UIView, metadata: TraitMetadata) {
        let newMaskPath = UIBezierPath(rect: backdropView.bounds)
        let newShape: KeyholeShape = metadata["keyholeShape"] ?? metadata[previous: "keyholeShape"] ?? .circle
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
        let oldShape: KeyholeShape = metadata[previous: "keyholeShape"] ?? metadata["keyholeShape"] ?? .circle
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

        let maskLayer = CAShapeLayer()
        maskLayer.fillRule = .evenOdd
        maskLayer.path = newMaskPath.cgPath

        if let anim = metadata.basicAnimation(keyPath: "path") {
            anim.fromValue = oldMaskPath.cgPath
            anim.toValue = newMaskPath.cgPath

            maskLayer.add(anim, forKey: nil)
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
        case circle

        init?(_ shape: String?, cornerRadius: Double? = nil) {
            switch shape {
            case "rectangle":
                // fallback to a tiny value instead of 0 so the path can animate nicely to other values
                self = .rectangle(cornerRadius: cornerRadius ?? .leastNonzeroMagnitude)
            case "circle":
                self = .circle
            default:
                return nil
            }
        }

        func path(for rect: CGRect) -> UIBezierPath {
            switch self {
            case .rectangle(let cornerRadius):
                return UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
            case .circle:
                // A circle that fully encompasses the target rectangle
                let radius = sqrt(pow(rect.width, 2) + pow(rect.height, 2)) / 2
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

private extension CGRect {
    var zeroed: CGRect {
        CGRect(x: midX, y: midY, width: 0, height: 0)
    }

    func spread(by spreadRadius: CGFloat?) -> CGRect {
        guard let radius = spreadRadius else { return self }
        return self.insetBy(dx: -radius, dy: -radius)
    }
}
