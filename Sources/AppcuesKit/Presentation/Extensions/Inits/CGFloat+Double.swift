//
//  CGFloat+Double.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

extension CGFloat {

    /// Init `CGFloat` from an experience JSON model value.
    init?(_ double: Double?) {
        if let double = double {
            self.init(double)
        } else {
            return nil
        }
    }
}
