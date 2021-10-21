//
//  AppcuesEncodingError.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal enum AppcuesEncodingError: Error {
    /// Non String, Number, Bool value.
    case unsupportedType
}
