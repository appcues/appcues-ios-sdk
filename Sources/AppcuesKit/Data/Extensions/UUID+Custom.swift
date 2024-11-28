//
//  UUID+Custom.swift
//  AppcuesKit
//
//  Created by Matt on 2022-04-08.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

extension UUID {
    var appcuesFormatted: String {
        return uuidString.lowercased()
    }
}
