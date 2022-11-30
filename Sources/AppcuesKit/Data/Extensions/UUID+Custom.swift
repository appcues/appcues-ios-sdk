//
//  UUID+Custom.swift
//  AppcuesKit
//
//  Created by Matt on 2022-04-08.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

// Allows overriding of UUID creation for determenistic testing.
extension UUID {
    static var generator: () -> UUID = UUID.init

    static func create() -> UUID {
        return UUID.generator()
    }

    var appcuesFormatted: String {
        return uuidString.lowercased()
    }
}
