//
//  NSDirectionalEdgeInsets+Style.swift
//  AppcuesKit
//
//  Created by Matt on 2023-06-20.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit

extension NSDirectionalEdgeInsets {
    @available(iOS 13.0, *)
    init(paddingFrom style: ExperienceComponent.Style?) {
        self.init(
            top: style?.paddingTop ?? 0,
            leading: style?.paddingLeading ?? 0,
            bottom: style?.paddingBottom ?? 0,
            trailing: style?.paddingTrailing ?? 0
        )
    }

    @available(iOS 13.0, *)
    init(marginFrom style: ExperienceComponent.Style?) {
        self.init(
            top: style?.marginTop ?? 0,
            leading: style?.marginLeading ?? 0,
            bottom: style?.marginBottom ?? 0,
            trailing: style?.marginTrailing ?? 0
        )
    }

}
