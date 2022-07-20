//
//  AppcuesStyle.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
internal struct AppcuesStyle {
    let padding: EdgeInsets
    let margin: EdgeInsets
    let height: CGFloat?
    let width: CGFloat?
    let fillWidth: Bool

    let alignment: Alignment
    let horizontalAlignment: HorizontalAlignment
    let verticalAlignment: VerticalAlignment

    let font: Font?
    let letterSpacing: CGFloat?
    let lineSpacing: CGFloat?
    let textAlignment: TextAlignment?
    let foregroundColor: Color?
    let backgroundColor: Color?
    let backgroundGradient: LinearGradient?
    let backgroundImage: ExperienceComponent.Style.BackgroundImage?
    let shadow: ExperienceComponent.Style.RawShadow?
    let cornerRadius: CGFloat?
    let borderColor: Color?
    let borderWidth: CGFloat?

    init(from model: ExperienceComponent.Style?) {
        self.padding = EdgeInsets(
            top: model?.paddingTop ?? 0,
            leading: model?.paddingLeading ?? 0,
            bottom: model?.paddingBottom ?? 0,
            trailing: model?.paddingTrailing ?? 0)
        self.margin = EdgeInsets(
            top: model?.marginTop ?? 0,
            leading: model?.marginLeading ?? 0,
            bottom: model?.marginBottom ?? 0,
            trailing: model?.marginTrailing ?? 0)
        self.height = CGFloat(model?.height)

        if let width = model?.width, width > 0 {
            self.width = CGFloat(width)
        } else {
            self.width = nil
        }
        self.fillWidth = model?.width?.isEqual(to: -1) ?? false

        self.alignment = Alignment(vertical: model?.verticalAlignment, horizontal: model?.horizontalAlignment) ?? .center
        self.horizontalAlignment = HorizontalAlignment(string: model?.horizontalAlignment) ?? .center
        self.verticalAlignment = VerticalAlignment(string: model?.verticalAlignment) ?? .center

        let fontSize = model?.fontSize ?? UIFont.labelFontSize
        self.font = Font(name: model?.fontName, size: fontSize)
        self.letterSpacing = CGFloat(model?.letterSpacing)
        if let lineHeight = CGFloat(model?.lineHeight) {
            self.lineSpacing = lineHeight - fontSize
        } else {
            self.lineSpacing = nil
        }
        self.textAlignment = TextAlignment(string: model?.textAlignment)
        self.foregroundColor = Color(dynamicColor: model?.foregroundColor)
        self.backgroundColor = Color(dynamicColor: model?.backgroundColor)
        self.backgroundGradient = LinearGradient(rawGradient: model?.backgroundGradient)
        self.backgroundImage = model?.backgroundImage
        self.shadow = model?.shadow
        self.cornerRadius = CGFloat(model?.cornerRadius)
        self.borderColor = Color(dynamicColor: model?.borderColor)
        self.borderWidth = CGFloat(model?.borderWidth)
    }
}
