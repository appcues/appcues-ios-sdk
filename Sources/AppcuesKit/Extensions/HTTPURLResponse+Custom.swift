//
//  HTTPURLResponse+Custom.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-12.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

extension HTTPURLResponse {
    var isSuccessStatusCode: Bool {
        (200...299).contains(statusCode)
    }
}
