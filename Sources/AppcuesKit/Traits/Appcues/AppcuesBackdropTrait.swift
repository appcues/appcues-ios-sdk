//
//  AppcuesBackdropTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-27.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

internal class AppcuesBackdropTrait: BackdropDecoratingTrait {
    static var type: String = "@appcues/backdrop"

    let groupID: String?
    let backgroundColor: UIColor?

    required init?(config: [String: Any]?) {
        self.groupID = config?["groupID"] as? String

        if let dynamicColor = config?["backgroundColor", decodedAs: ExperienceComponent.Style.DynamicColor.self] {
            self.backgroundColor = UIColor(dynamicColor: dynamicColor)
        } else {
            return nil
        }
    }

    func decorate(backdropView: UIView) throws {
        backdropView.backgroundColor = backgroundColor
    }
}
