//
//  Dictionary+Merging.swift
//  AppcuesKit
//
//  Created by James Ellis on 11/2/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

extension Dictionary {
    /// Creates a dictionary by merging the given dictionary into this dictionary,
    /// preferring the new value for duplicate keys.
    func merging(_ other: [Key: Value]) -> [Key: Value] {
        self.merging(other) { _, new in new }
    }
}
