//
//  ExperimentalBlurBackdropTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-27.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class ExperimentalBlurBackdropTrait: BackdropDecoratingTrait {
    static var type: String = "@experimental/blur-backdrop"

    let style: UIBlurEffect.Style

    required init?(config: [String: Any]?) {
        self.style = UIBlurEffect.Style(string: config?["style"] as? String)
    }

    func decorate(backdropView: UIView) throws {
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        backdropView.addSubview(blurView)
        blurView.pin(to: backdropView)
    }
}

@available(iOS 13.0, *)
extension UIBlurEffect.Style {
    init(string: String?) {
        switch string {
        case "ultraThin": self = .systemUltraThinMaterial
        case "thin": self = .systemThinMaterial
        case "thick": self = .systemThickMaterial
        default: self = .systemMaterial
        }
    }
}
