//
//  Collection+Custom.swift
//  AppcuesKit
//
//  Created by Matt on 2022-04-28.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

extension Collection {
    func separate(predicate: (Iterator.Element) -> Bool) -> (matching: [Iterator.Element], notMatching: [Iterator.Element]) {
        var separated: ([Iterator.Element], [Iterator.Element]) = ([], [])
        for element in self {
            if predicate(element) {
                separated.0.append(element)
            } else {
                separated.1.append(element)
            }
        }
        return separated
    }

    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
