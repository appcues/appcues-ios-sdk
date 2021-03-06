//
//  TraitError.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-28.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

/// An `Error` preventing an Experience from being presented.
public struct TraitError: Error, CustomStringConvertible {

    /// A description of the nature of the error.
    ///
    /// This value will be logged to Appcues Studio.
    public var description: String
}
