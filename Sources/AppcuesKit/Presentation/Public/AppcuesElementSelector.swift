//
//  AppcuesElementSelector.swift
//  AppcuesKit
//
//  Created by James Ellis on 3/22/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import Foundation

/// The base type for a selector that identifies a view in the current application UI.
@objc
open class AppcuesElementSelector: NSObject, Encodable {
    // class rather than protocol, for @objc compatibility when adhering to Encodable

    /// Evaluate how closely this selector matches with the given target selector.
    ///
    /// Any value greater than zero means there is a match. The higher the value, the more exact the match.
    /// In the cases of selectors with multiple identifying attributes, there may be partial matches with lower values,
    /// and exact matches with higher values. Any negative value indicates no match.
    ///
    /// - Returns: Value for the quality of selector match.
    open func evaluateMatch(for target: AppcuesElementSelector) -> Int {
        // derived types provide actual matching logic based on selector implementations
        // this base type has no selector properties and, by default, no matches
        return 0
    }
}
