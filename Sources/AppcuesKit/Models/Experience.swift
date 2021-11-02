//
//  Experience.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal struct Experience: Decodable {

    struct Step: Decodable {
        let id: UUID
        let contentType: String
        let content: ExperienceComponent
    }

    let id: UUID
    let name: String
    // tags, theme, actions, traits
    let steps: [Step]
}
