//
//  Theme.swift
//  AppcuesKit
//
//  Created by Matt on 2023-12-20.
//  Copyright © 2023 Appcues. All rights reserved.
//

import Foundation

internal struct Theme: Decodable {
    let id: UUID
    let name: String
    private let styles: [String: ExperienceComponent.Style]

    subscript (themeID: String?) -> ExperienceComponent.Style? {
        guard let themeID = themeID else { return nil }
        return styles[themeID]
    }

    enum CodingKeys: CodingKey {
        case id
        case name
        case styles

        case theme // legacy format
    }

    enum LegacyCodingKeys: CodingKey {
        case theme
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let id = try? container.decode(UUID.self, forKey: .id) {
            self.id = id
            self.name = try container.decode(String.self, forKey: .name)
            self.styles = try container.decode([String : ExperienceComponent.Style].self, forKey: .styles)
        } else {
            // If we can't decode a new format of theme, try a web-style legacy theme
            let theme = try container.decode(LegacyTheme.self, forKey: .theme)

            self.id = UUID()
            self.name = "Legacy"
            self.styles = theme.styles
        }
    }
}

private struct LegacyTheme: Decodable {
    let styles: [String: ExperienceComponent.Style]

    enum CodingKeys: CodingKey {
        case json
    }

    enum JSONKeys: CodingKey {
        case button, general, patterns
    }

    enum ButtonKeys: CodingKey {
        case borderRadius, fontSize, primary, secondary
    }

    enum ButtonTypeKeys: CodingKey {
        case backgroundColor, borderColor, borderWidth, color
    }

    enum GeneralKeys: CodingKey {
        case bodyFont, bodyFontColor, headerFont
    }

    enum PatternsKeys: CodingKey {
        case modal, tooltip
    }

    enum PatternTypeKeys: CodingKey {
        case backgroundColor, color, borderRadius, shadow, backdropColor, backdropOpacity
    }

    enum ShadowKeys: CodingKey {
        case blur, color, distance
    }

    enum DistanceKeys: CodingKey {
        case x, y
    }


    init(from decoder: Decoder) throws {
        let rootContainer = try decoder.container(keyedBy: CodingKeys.self)
        let jsonContainer = try rootContainer.nestedContainer(keyedBy: JSONKeys.self, forKey: .json)

        var styles: [String: ExperienceComponent.Style] = [:]

        let generalContainer = try jsonContainer.nestedContainer(keyedBy: GeneralKeys.self, forKey: .general)
        let bodyFont = try generalContainer.decode(String.self, forKey: .bodyFont)
        let bodyFontColor = try generalContainer.decode(String.self, forKey: .bodyFontColor)
        let headerFont = try generalContainer.decode(String.self, forKey: .headerFont)

        styles["text"] = ExperienceComponent.Style(
            fontName: bodyFont.extractFontName(),
            foregroundColor: ExperienceComponent.Style.DynamicColor(light: bodyFontColor, dark: nil)
        )

        styles["header"] = ExperienceComponent.Style(
            fontName: headerFont.extractFontName(),
            foregroundColor: ExperienceComponent.Style.DynamicColor(light: bodyFontColor, dark: nil)
        )

        let buttonContainer = try jsonContainer.nestedContainer(keyedBy: ButtonKeys.self, forKey: .button)
        let buttonBorderRadius = try buttonContainer.decode(String.self, forKey: .borderRadius)
        let buttonFontSize = try buttonContainer.decode(String.self, forKey: .fontSize)
        let primaryButtonContainer = try buttonContainer.nestedContainer(keyedBy: ButtonTypeKeys.self, forKey: .primary)
        let primaryButtonBackgroundColor = try primaryButtonContainer.decode(String.self, forKey: .backgroundColor)
        let primaryButtonBorderColor = try primaryButtonContainer.decode(String.self, forKey: .borderColor)
        let primaryButtonBorderWidth = try primaryButtonContainer.decode(String.self, forKey: .borderWidth)
        let primaryButtonForegroundColor = try primaryButtonContainer.decode(String.self, forKey: .color)

        styles["primaryButtonText"] = ExperienceComponent.Style(
            fontName: bodyFont.extractFontName(),
            fontSize: buttonFontSize.pxToNumber(),
            foregroundColor: ExperienceComponent.Style.DynamicColor(light: primaryButtonForegroundColor, dark: nil)
        )

        styles["primaryButton"] = ExperienceComponent.Style(
            fontSize: buttonFontSize.pxToNumber(),
            backgroundColor: ExperienceComponent.Style.DynamicColor(light: primaryButtonBackgroundColor, dark: nil),
            cornerRadius: buttonBorderRadius.pxToNumber(),
            borderColor: ExperienceComponent.Style.DynamicColor(light: primaryButtonBorderColor, dark: nil),
            borderWidth: primaryButtonBorderWidth.pxToNumber()
        )

        let secondaryButtonContainer = try buttonContainer.nestedContainer(keyedBy: ButtonTypeKeys.self, forKey: .secondary)
        let secondaryButtonBackgroundColor = try secondaryButtonContainer.decode(String.self, forKey: .backgroundColor)
        let secondaryButtonBorderColor = try secondaryButtonContainer.decode(String.self, forKey: .borderColor)
        let secondaryButtonBorderWidth = try secondaryButtonContainer.decode(String.self, forKey: .borderWidth)
        let secondaryButtonForegroundColor = try secondaryButtonContainer.decode(String.self, forKey: .color)

        styles["secondaryButtonText"] = ExperienceComponent.Style(
            fontName: bodyFont.extractFontName(),
            fontSize: buttonFontSize.pxToNumber(),
            foregroundColor: ExperienceComponent.Style.DynamicColor(light: secondaryButtonForegroundColor, dark: nil)
        )

        styles["secondaryButton"] = ExperienceComponent.Style(
            fontSize: buttonFontSize.pxToNumber(),
            backgroundColor: ExperienceComponent.Style.DynamicColor(light: secondaryButtonBackgroundColor, dark: nil),
            cornerRadius: buttonBorderRadius.pxToNumber(),
            borderColor: ExperienceComponent.Style.DynamicColor(light: secondaryButtonBorderColor, dark: nil),
            borderWidth: secondaryButtonBorderWidth.pxToNumber()
        )

        let patternsContainer = try jsonContainer.nestedContainer(keyedBy: PatternsKeys.self, forKey: .patterns)

        let modalContainer = try patternsContainer.nestedContainer(keyedBy: PatternTypeKeys.self, forKey: .modal)
        let tooltipContainer = try patternsContainer.nestedContainer(keyedBy: PatternTypeKeys.self, forKey: .tooltip)

        let patternCornerRadius = try tooltipContainer.decode(String.self, forKey: .borderRadius)

        let shadowContainer = try tooltipContainer.nestedContainer(keyedBy: ShadowKeys.self, forKey: .shadow)
        let shadowRadius = try shadowContainer.decode(String.self, forKey: .blur)
        let shadowColor = try shadowContainer.decode(String.self, forKey: .color)
        let shadowDistanceContainer = try shadowContainer.nestedContainer(keyedBy: DistanceKeys.self, forKey: .distance)
        let shadowX = try shadowDistanceContainer.decode(String.self, forKey: .x)
        let shadowY = try shadowDistanceContainer.decode(String.self, forKey: .y)

        let patternShadow: ExperienceComponent.Style.RawShadow?

        if let convertedShadowColor = shadowColor.hslaToHex() {
            patternShadow = ExperienceComponent.Style.RawShadow(
                color: ExperienceComponent.Style.DynamicColor(light: convertedShadowColor, dark: nil),
                radius: shadowRadius.pxToNumber() ?? 0,
                x: shadowX.pxToNumber() ?? 0,
                y: shadowY.pxToNumber() ?? 0
            )
        } else {
            patternShadow = nil
        }

        let backdropColor = try modalContainer.decode(String.self, forKey: .backdropColor)
        let backdropOpacity = try modalContainer.decode(Double.self, forKey: .backdropOpacity)
        let backdropOpacityHex = String(format:"%02X", Int(255 * backdropOpacity))

        styles["backdrop"] = ExperienceComponent.Style(
            backgroundColor: ExperienceComponent.Style.DynamicColor(light: backdropColor + backdropOpacityHex, dark: nil)
        )

        let modalForegroundColor = try modalContainer.decode(String.self, forKey: .color)
        let modalBackgroundColor = try modalContainer.decode(String.self, forKey: .backgroundColor)

        styles["modal"] = ExperienceComponent.Style(
            foregroundColor: ExperienceComponent.Style.DynamicColor(light: modalForegroundColor, dark: nil),
            backgroundColor: ExperienceComponent.Style.DynamicColor(light: modalBackgroundColor, dark: nil),
            shadow: patternShadow,
            cornerRadius: patternCornerRadius.pxToNumber()
        )

        let tooltipForegroundColor = try tooltipContainer.decode(String.self, forKey: .color)
        let tooltipBackgroundColor = try tooltipContainer.decode(String.self, forKey: .backgroundColor)

        styles["tooltip"] = ExperienceComponent.Style(
            foregroundColor: ExperienceComponent.Style.DynamicColor(light: tooltipForegroundColor, dark: nil),
            backgroundColor: ExperienceComponent.Style.DynamicColor(light: tooltipBackgroundColor, dark: nil),
            shadow: patternShadow,
            cornerRadius: patternCornerRadius.pxToNumber()
        )

        self.styles = styles
    }
}

extension String {
    func extractFontName() -> String? {
        guard let namedFont = self.split(separator: ",").first else { return nil }

        return String(namedFont).replacingOccurrences(of: "'", with: "")
    }

    func pxToNumber() -> Double? {
        Double(self.dropLast(2))
    }

    // Convert something like hsla(0,0%,13%,.6) to a hex value
    func hslaToHex() -> String? {
        if self == "transparent" { return "#00000000" }

        guard self.hasPrefix("hsla(") else { return nil }

        let parts = self.dropFirst(5).dropLast(1).split(separator: ",")

        guard parts.count == 4 else { return nil }

        let a = Int(parts[3]) ?? 1

        guard let h = Double(parts[0].trimmingCharacters(in: .decimalDigits.inverted)),
              let s = Double(parts[1].trimmingCharacters(in: .decimalDigits.inverted)),
              let l = Double(parts[2].trimmingCharacters(in: .decimalDigits.inverted)) else { return nil }

        return hslToHex(h, s, l) + String(format:"%02X", Int(255 * a))
    }

    private func hslToHex(_ h: Double, _ s: Double, _ l: Double) -> String {
        let s = s / 100
        let l = l / 100
        let a = s * min(l, 1 - l) / 100

        func f(_ n: Double) -> String {
            let k = (n + h / 30).truncatingRemainder(dividingBy: 12)
            let color = l - a * max(Swift.min(k - 3, 9 - k, 1), -1)
            return String(format:"%02X", Int(255 * color))
        }

        return "#\(f(0))\(f(8))\(f(4))";
    }

}
