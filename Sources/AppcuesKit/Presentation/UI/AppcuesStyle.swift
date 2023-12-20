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
    let borderInset: EdgeInsets
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

    init(from model: ExperienceComponent.Style?, theme: Theme?, contentMode: ContentMode? = nil, aspectRatio: CGFloat? = nil) {
        let themeStyle = theme?[model?.themeID]

        self.padding = EdgeInsets(
            top: model?.paddingTop ?? themeStyle?.paddingTop ?? 0,
            leading: model?.paddingLeading ?? themeStyle?.paddingLeading ?? 0,
            bottom: model?.paddingBottom ?? themeStyle?.paddingBottom ?? 0,
            trailing: model?.paddingTrailing ?? themeStyle?.paddingTrailing ?? 0
        )
        self.margin = EdgeInsets(
            top: model?.marginTop ?? themeStyle?.marginTop ?? 0,
            leading: model?.marginLeading ?? themeStyle?.marginLeading ?? 0,
            bottom: model?.marginBottom ?? themeStyle?.marginBottom ?? 0,
            trailing: model?.marginTrailing ?? themeStyle?.marginTrailing ?? 0
        )
        self.height = CGFloat(model?.height ?? themeStyle?.height)

        if let width = model?.width ?? themeStyle?.width, width > 0 {
            self.width = CGFloat(width)
        } else {
            self.width = nil
        }
        self.fillWidth = (model?.width ?? themeStyle?.width)?.isEqual(to: -1) ?? false

        self.alignment = Alignment(
            vertical: model?.verticalAlignment ?? themeStyle?.verticalAlignment,
            horizontal: model?.horizontalAlignment ?? themeStyle?.horizontalAlignment
        ) ?? .center
        self.horizontalAlignment = HorizontalAlignment(string: model?.horizontalAlignment ?? themeStyle?.horizontalAlignment) ?? .center
        self.verticalAlignment = VerticalAlignment(string: model?.verticalAlignment ?? themeStyle?.verticalAlignment) ?? .center

        let fontSize: CGFloat = model?.fontSize ?? themeStyle?.fontSize ?? UIFont.labelFontSize
        self.font = Font(name: model?.fontName ?? themeStyle?.fontName, size: fontSize)
        self.letterSpacing = CGFloat(model?.letterSpacing ?? themeStyle?.letterSpacing)
        if let lineHeight = CGFloat(model?.lineHeight ?? themeStyle?.lineHeight) {
            self.lineSpacing = lineHeight - fontSize
        } else {
            self.lineSpacing = nil
        }
        self.textAlignment = TextAlignment(string: model?.textAlignment ?? themeStyle?.textAlignment)
        self.foregroundColor = Color(dynamicColor: model?.foregroundColor ?? themeStyle?.foregroundColor)
        self.backgroundColor = Color(dynamicColor: model?.backgroundColor ?? themeStyle?.backgroundColor)
        self.backgroundGradient = LinearGradient(rawGradient: model?.backgroundGradient ?? themeStyle?.backgroundGradient)
        self.backgroundImage = model?.backgroundImage ?? themeStyle?.backgroundImage
        self.shadow = model?.shadow ?? themeStyle?.shadow
        self.cornerRadius = CGFloat(model?.cornerRadius ?? themeStyle?.cornerRadius)
        self.borderColor = Color(dynamicColor: model?.borderColor ?? themeStyle?.borderColor)
        self.borderWidth = CGFloat(model?.borderWidth ?? themeStyle?.borderWidth)

        // Border insets should only be applied on fixed size views - so for those with a
        // fixed height, for instance, apply a top and bottom inset. For those with a
        // fixed width, apply leading and trailing inset (or sometimes both).
        // This is factored in the base style object created above. If size is not constrained,
        // then any border is applied on top of the intrinsic size of the view - growing the
        // overall view frame as needed.
        //
        // For images, they may also have one dimension defined and the other defined
        // using an aspect ratio - so we have to handle that special case here and use a custom
        // borderInset
        let willApplyAspectRatio = contentMode != nil && aspectRatio != nil
        let hasWidth = self.width != nil || self.fillWidth
        let hasHeight = self.height != nil
        let borderInsetSize: CGFloat = self.borderWidth ?? 0.0

        self.borderInset = EdgeInsets(
            top: hasHeight || (hasWidth && willApplyAspectRatio) ? borderInsetSize : 0,
            leading: hasWidth || (hasHeight && willApplyAspectRatio) ? borderInsetSize : 0,
            bottom: hasHeight || (hasWidth && willApplyAspectRatio) ? borderInsetSize : 0,
            trailing: hasWidth || (hasHeight && willApplyAspectRatio) ? borderInsetSize : 0
        )
    }
}
