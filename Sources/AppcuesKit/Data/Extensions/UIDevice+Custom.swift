//
//  UIDevice+Custom.swift
//  AppcuesKit
//
//  Created by James Ellis on 11/8/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

extension UIDevice {
    static var identifier: String {
        (current.identifierForVendor ?? UUID()).appcuesFormatted
    }
}
