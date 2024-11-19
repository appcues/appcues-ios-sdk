//
//  NSDirectionalEdgeInsets+Style.swift
//  AppcuesKit
//
//  Created by Matt on 2023-06-20.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit

extension NSDirectionalEdgeInsets {
    init(paddingFrom style: ExperienceComponent.Style?, fallback: CGFloat = 0) {
        self.init(
            top: style?.paddingTop ?? fallback,
            leading: style?.paddingLeading ?? fallback,
            bottom: style?.paddingBottom ?? fallback,
            trailing: style?.paddingTrailing ?? fallback
        )
    }

    init(marginFrom style: ExperienceComponent.Style?, fallback: CGFloat = 0) {
        self.init(
            top: style?.marginTop ?? fallback,
            leading: style?.marginLeading ?? fallback,
            bottom: style?.marginBottom ?? fallback,
            trailing: style?.marginTrailing ?? fallback
        )
    }

}
