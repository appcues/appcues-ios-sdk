//
//  StepGroup.swift
//  Appcues
//
//  Created by Matt on 2021-10-15.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

/// A type that is included in a `Flow` step.
internal protocol StepGroup {
    var id: String { get }
    var index: Int { get }
}
