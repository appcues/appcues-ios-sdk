//
//  ElementSelector.swift
//  AppcuesKit
//
//  Created by James Ellis on 1/11/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import Foundation

internal struct ElementSelector: Codable {
    let accessibilityIdentifier: String?
    let description: String?
    let tag: String?
    let id: String?

    init?(accessibilityIdentifier: String?, description: String?, tag: String?, id: String?) {
        // must have at least one identifiable property to be a valid selector
        if accessibilityIdentifier == nil &&
            description == nil &&
            tag == nil &&
            id == nil {
            return nil
        }

        self.accessibilityIdentifier = accessibilityIdentifier
        self.description = description
        self.tag = tag
        self.id = id
    }
}
