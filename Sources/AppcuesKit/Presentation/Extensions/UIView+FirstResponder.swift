//
//  UIView+FirstResponder.swift
//  AppcuesKit
//
//  Created by Matt on 2022-10-26.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

extension UIView {
    var firstResponder: UIView? {
        if isFirstResponder {
            return self
        }

        for subview in subviews {
            if let firstResponder = subview.firstResponder {
                return firstResponder
            }
        }

        return nil
    }
}
