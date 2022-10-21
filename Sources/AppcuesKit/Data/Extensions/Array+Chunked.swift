//
//  Array+Chunked.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/24/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
