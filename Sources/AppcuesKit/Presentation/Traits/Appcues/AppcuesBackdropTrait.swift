//
//  AppcuesBackdropTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-27.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class AppcuesBackdropTrait: BackdropDecoratingTrait {
    static var type: String = "@appcues/backdrop"

    let backgroundColor: UIColor?

    required init?(config: [String: Any]?, level: ExperienceTraitLevel) {
        if let dynamicColor = config?["backgroundColor", decodedAs: ExperienceComponent.Style.DynamicColor.self] {
            self.backgroundColor = UIColor(dynamicColor: dynamicColor)
        } else {
            return nil
        }
    }

    func decorate(backdropView: UIView) throws {
        backdropView.backgroundColor = backgroundColor
    }

    func undecorate(backdropView: UIView) throws {
        backdropView.backgroundColor = nil
    }
}
