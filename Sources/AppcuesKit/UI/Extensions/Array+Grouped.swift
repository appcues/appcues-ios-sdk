//
//  Array+Grouped.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-05.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

extension Array {

    /// Convert a 1 dimensional array into a dictionary of items grouped and keyed by the values of the specified keyPath.
    func grouped<T: Equatable>(by keyPath: KeyPath<Element, T>) -> [T: [Element]] {
        var data: [T: [Element]] = [:]

        self.forEach { element in
            let key = element[keyPath: keyPath]
            if data[key] != nil {
                data[key]?.append(element)
            } else {
                data[key] = [element]
            }
        }

        return data
    }
}
