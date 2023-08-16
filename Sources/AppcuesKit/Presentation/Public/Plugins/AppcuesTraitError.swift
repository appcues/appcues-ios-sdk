//
//  AppcuesTraitError.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-28.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

/// An `Error` preventing an Experience from being presented.
internal struct AppcuesTraitError: Error, CustomStringConvertible {

    /// A description of the nature of the error.
    ///
    /// This value will be logged to Appcues Studio.
    internal var description: String

    /// Creates an instance of an error.
    /// - Parameter description: A description of the nature of the error.
    internal init(description: String) {
        self.description = description
    }
}
