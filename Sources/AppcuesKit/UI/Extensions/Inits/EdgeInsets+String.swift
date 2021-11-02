//
//  EdgeInsets+String.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

extension EdgeInsets {

    /// Init `EdgeInsets` from an experience JSON model value.
    init?(string: String?) {
        let numberFormatter = NumberFormatter()
        let vals = string?
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .compactMap { numberFormatter.number(from: $0) }
            .map { $0.doubleValue } ?? []

        if vals.count == 4 {
            self = EdgeInsets(top: vals[0], leading: vals[1], bottom: vals[2], trailing: vals[3])
        } else {
            return nil
        }
    }
}
