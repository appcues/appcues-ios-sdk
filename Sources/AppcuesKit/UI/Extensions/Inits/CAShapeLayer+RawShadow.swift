//
//  CAShapeLayer+RawShadow.swift
//  AppcuesKit
//
//  Created by Matt on 2021-12-16.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

extension CAShapeLayer {

    /// Init `CAShapeLayer` from an experience JSON model value.
    convenience init?(shadowModel: ExperienceComponent.Style.RawShadow?) {
        guard let shadowModel = shadowModel else { return nil }

        self.init()

        fillColor = UIColor.clear.cgColor
        shadowColor = UIColor(dynamicColor: shadowModel.color)?.cgColor
        shadowOpacity = 1
        shadowRadius = shadowModel.radius
        shadowOffset = CGSize(width: shadowModel.x, height: shadowModel.y)
    }
}
