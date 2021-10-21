//
//  ModalGroup.Pattern+UI.swift
//  Appcues
//
//  Created by Matt on 2021-10-15.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

extension ModalGroup.Pattern {
    var modalPresentationStyle: UIModalPresentationStyle {
        switch self {
        case .modal:
            return .formSheet
        case .fullscreen:
            return .overFullScreen
        case .shorty:
            return .pageSheet
        }
    }
}
