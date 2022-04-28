//
//  Collection+SafeIndex.swift
//  AppcuesKit
//
//  Created by Matt on 2022-04-28.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
