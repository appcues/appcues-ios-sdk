//
//  Sequence+CompactMapFirst.swift
//  AppcuesKit
//
//  Created by Matt on 2022-10-06.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

extension Sequence {
    // Functionally the same as Sequence.compactMap().first(), except returns immediately upon finding the first item.
    func compactMapFirst<ElementOfResult>(_ transform: (Element) throws -> ElementOfResult?) rethrows -> ElementOfResult? {
        for item in self {
            if let result = try transform(item) {
                return result
            }
        }

        return nil
    }
}
