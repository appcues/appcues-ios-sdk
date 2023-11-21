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
    internal let description: String

    /// When set, this value can indicate a number of milliseconds after which re-application
    /// of traits can be attempted, to try to auto-recover from this error.
    internal let retryMilliseconds: Int?

    internal let recoverable: Bool

    /// Creates an instance of an error.
    /// - Parameters:
    ///   - description: A description of the nature of the error.
    ///   - retryMilliseconds: The number of milliseconds to wait before attempting to re-apply traits after this error.
    internal init(description: String, retryMilliseconds: Int? = nil, recoverable: Bool = false) {
        self.description = description
        self.retryMilliseconds = retryMilliseconds.flatMap { max(0, $0) } // coerce zero or positive value
        self.recoverable = recoverable
    }
}
