//
//  Template.swift
//  AppcuesKit
//
//  Created by Matt on 2022-12-20.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class Template: ObservableObject {
    @Published private(set) var captures: [Capture] = []
    private(set) var allColors: [String] = []
    private(set) var allShades: [String] = []
    private(set) var customFonts: [String] = []
    private(set) var systemFonts: [String] = []

    @Published var headerTextStyle: ExperienceComponent.Style
    @Published var bodyTextStyle: ExperienceComponent.Style
    @Published var primaryButtonStyle: ExperienceComponent.Style
    @Published var primaryButtonTextStyle: ExperienceComponent.Style
    @Published var secondaryButtonStyle: ExperienceComponent.Style
    @Published var secondaryButtonTextStyle: ExperienceComponent.Style

    init() {
        headerTextStyle = ExperienceComponent.Style(
            marginBottom: 15,
            fontName: "System Default Bold",
            fontSize: 22,
            textAlignment: "center")

        bodyTextStyle = ExperienceComponent.Style(
            marginBottom: 15,
            fontSize: 17,
            textAlignment: "center")

        primaryButtonStyle = ExperienceComponent.Style(
            paddingTop: 12,
            paddingLeading: 24,
            paddingBottom: 12,
            paddingTrailing: 24,
            marginBottom: 20,
            backgroundColor: ExperienceComponent.Style.DynamicColor(light: "#5C5CFF", dark: nil),
            cornerRadius: 6)

        primaryButtonTextStyle = ExperienceComponent.Style(
            fontSize: 17,
            foregroundColor: ExperienceComponent.Style.DynamicColor(light: "#FFFFFF", dark: nil))

        secondaryButtonStyle = ExperienceComponent.Style(
            paddingTop: 12,
            paddingLeading: 24,
            paddingBottom: 12,
            paddingTrailing: 24,
            marginBottom: 20,
            backgroundColor: ExperienceComponent.Style.DynamicColor(light: "#FFFFFF", dark: nil),
            cornerRadius: 6,
            borderColor: ExperienceComponent.Style.DynamicColor(light: "#5C5CFF", dark: nil),
            borderWidth: 1)

        secondaryButtonTextStyle = ExperienceComponent.Style(
            fontSize: 17,
            foregroundColor: ExperienceComponent.Style.DynamicColor(light: "#5C5CFF", dark: nil))
    }

    func addCapture(capture: Capture) {
        captures.append(capture)
        recompute()
    }

    func removeCapture(capture: Capture) {
        captures.removeAll { capture.id == $0.id }
        recompute()
    }

    func set<T>(component: ReferenceWritableKeyPath<Template, ExperienceComponent.Style>, property: WritableKeyPath<ExperienceComponent.Style, T>, value: T) {
        self[keyPath: component][keyPath: property] = value
    }

    func recompute() {
        let (colors, shades) = captures
            .flatMap { $0.includedColors() }
            .separate { !$0.isGrayscaleHex }
        self.allColors = colors.sortedByFrequency()
        self.allShades = shades.sortedByFrequency()

        let (custom, system) = captures.flatMap { $0.includedFonts() }
            .map { $0.formattedFontName }
            .separate { !$0.isSystemFont }
        self.customFonts = custom.sortedByFrequency()
        self.systemFonts = system.sortedByFrequency()
    }

    func shouldCapture(screenName: String) -> Bool {
        captures.firstIndex { $0.name == screenName } == nil
    }

    func experience() throws -> Experience {
        let encoder = JSONEncoder()
        let encodedHeaderTextStyle = try encoder.encode(headerTextStyle)
        let encodedBodyTextStyle = try encoder.encode(bodyTextStyle)
        let encodedPrimaryButtonStyle = try encoder.encode(primaryButtonStyle)
        let encodedPrimaryButtonTextStyle = try encoder.encode(primaryButtonTextStyle)
        let encodedSecondaryButtonStyle = try encoder.encode(secondaryButtonStyle)
        let encodedSecondaryButtonTextStyle = try encoder.encode(secondaryButtonTextStyle)

        let data = """
        {
            "id": "f4fbfff3-126a-4fce-93d0-660baad7be29",
            "name": "Generated Template",
            "type": "mobile",
            "tags": [],
            "theme": "",
            "actions": {},
            "traits": [],
            "steps": [
                {
                    "id": "9aee27d3-4235-42fb-aa16-5e14b95b5aab",
                    "type": "group",
                    "actions": {},
                    "traits": [
                        {
                            "type": "@appcues/modal",
                            "config": {
                                "presentationStyle": "dialog",
                                "style": {
                                    "cornerRadius": 8,
                                    "backgroundColor": { "light": "#ffffff", "dark": "#000000" },
                                    "shadow": {
                                        "color": { "light": "#777777ee" },
                                        "radius": 14,
                                        "x": 0,
                                        "y": 3
                                    }
                                }
                            }
                        },
                        {
                            "type": "@appcues/skippable"
                        },
                        {
                            "type": "@appcues/backdrop",
                            "config": {
                                "backgroundColor": { "light": "#0000004d", "dark": "#ffffff4d" }
                            }
                        }
                    ],
                    "children": [
                        {
                            "id": "e3f83087-11ed-4ae6-95c5-867917e3eb7a",
                            "type": "modal",
                            "parentId": "9aee27d3-4235-42fb-aa16-5e14b95b5aab",
                            "contentType": "application/json",
                            "content": {
                                "type": "stack",
                                "orientation": "vertical",
                                "id": "fca5a243-8eda-470e-b935-590e3cb88d7b",
                                "style": {},
                                "items": [
                                    {
                                        "type": "stack",
                                        "id": "7effa302-c1c7-4289-9d08-7d8d84be6afe",
                                        "orientation": "horizontal",
                                        "distribution": "equal",
                                        "items": [
                                            {
                                                "type": "block",
                                                "blockType": "image",
                                                "id": "e31fed04-767d-47b3-a8ad-9ba8c913a91f",
                                                "content": {
                                                    "type": "image",
                                                    "id": "48befaa3-455a-4730-857e-d12d3eb8ae33",
                                                    "imageUrl": "https://res.cloudinary.com/dnjrorsut/image/upload/v1635971825/98227/oh5drlvojb1spaetc1ol.jpg",
                                                    "blurHash": "LDAmob}[k6tSxyoMNFR*005RaiV?",
                                                    "contentMode": "fill",
                                                    "intrinsicSize": {
                                                        "width": 1920,
                                                        "height": 1280
                                                    },
                                                    "accessibilityLabel": "Mountains at night",
                                                    "style": {
                                                        "marginBottom": 20
                                                    }
                                                }
                                            }
                                        ]
                                    },
                                    {
                                        "type": "stack",
                                        "id": "f568bf70-c599-4818-8958-05475bf37352",
                                        "orientation": "horizontal",
                                        "distribution": "equal",
                                        "items": [
                                            {
                                                "type": "block",
                                                "blockType": "text",
                                                "id": "91443351-cdef-4d63-a034-0a1a82500413",
                                                "content": {
                                                    "type": "text",
                                                    "id": "486cd991-4b02-4fa6-b737-bf3bf039b0c5",
                                                    "text": "Ready to make your workflow simpler?",
                                                    "style": \(String(data: encodedHeaderTextStyle, encoding: .utf8)!)
                                                }
                                            }
                                        ]
                                    },
                                    {
                                        "type": "stack",
                                        "id": "1b5d3cee-341d-4e6d-8691-ba947bb3a805",
                                        "orientation": "horizontal",
                                        "distribution": "equal",
                                        "items": [
                                            {
                                                "type": "block",
                                                "blockType": "text",
                                                "id": "3fcd7b90-9905-4a66-938a-7768b35f57d1",
                                                "content": {
                                                    "type": "text",
                                                    "id": "4693cb43-669d-4d03-9ae3-55879905f529",
                                                    "text": "Take a few moments to learn how to best use our features.",
                                                    "style": \(String(data: encodedBodyTextStyle, encoding: .utf8)!)
                                                }
                                            }
                                        ]
                                    },
                                    {
                                        "type": "stack",
                                        "id": "154e2661-8c40-4236-a2b3-e9e12a4d824b",
                                        "orientation": "horizontal",
                                        "distribution": "equal",
                                        "style": {},
                                        "items": [
                                            {
                                                "type": "block",
                                                "blockType": "button",
                                                "id": "96d0e52f-c46f-4f92-ae1a-2d40bbf3b607",
                                                "content": {
                                                    "type": "button",
                                                    "id": "b947f397-80bd-4dc2-8264-850333609558",
                                                    "content": {
                                                        "type": "text",
                                                        "id": "00591d74-20b6-4377-af5f-c67571d67e27",
                                                        "text": "Primary Button",
                                                        "style": \(String(data: encodedPrimaryButtonTextStyle, encoding: .utf8)!)
                                                    },
                                                    "style": \(String(data: encodedPrimaryButtonStyle, encoding: .utf8)!)
                                                }
                                            }
                                        ]
                                    },
                                    {
                                        "type": "stack",
                                        "id": "39588402-ada2-4939-b259-773e1808c12d",
                                        "orientation": "horizontal",
                                        "distribution": "equal",
                                        "style": {},
                                        "items": [
                                            {
                                                "type": "block",
                                                "blockType": "button",
                                                "id": "8440fd1b-8c3b-4e05-8807-b9e12d92ff88",
                                                "content": {
                                                    "type": "button",
                                                    "id": "bba2ad1b-17fa-4311-8b84-e05a12abb95c",
                                                    "content": {
                                                        "type": "text",
                                                        "id": "20f5a281-e27a-48f4-a236-a2017214a692",
                                                        "text": "Secondary Button",
                                                        "style": \(String(data: encodedSecondaryButtonTextStyle, encoding: .utf8)!)
                                                    },
                                                    "style": \(String(data: encodedSecondaryButtonStyle, encoding: .utf8)!)
                                                }
                                            }
                                        ]
                                    }
                                ]
                            },
                            "traits": [],
                            "actions": {
                                "b947f397-80bd-4dc2-8264-850333609558": [
                                    {
                                        "on": "tap",
                                        "type": "@appcues/continue"
                                    }
                                ],
                                "bba2ad1b-17fa-4311-8b84-e05a12abb95c": [
                                    {
                                        "on": "tap",
                                        "type": "@appcues/continue"
                                    }
                                ]
                            }
                        }
                    ]
                }

            ]
        }
        """.data(using: .utf8)

        guard let data = data else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "data corrupted"))
        }

        return try JSONDecoder().decode(Experience.self, from: data)
    }
}

internal struct Capture: Encodable, Identifiable {
    struct Position: Encodable {
        // swiftlint:disable:next identifier_name
        let x: CGFloat
        // swiftlint:disable:next identifier_name
        let y: CGFloat
        let width: CGFloat
        let height: CGFloat

        init(_ cgRect: CGRect) {
            self.x = cgRect.origin.x
            self.y = cgRect.origin.y
            self.width = cgRect.width
            self.height = cgRect.height
        }
    }
    struct Node: Encodable {
        let type: String
        let absolutePosition: Position
        let children: [Node]

        let colors: [String]
        let font: String?

        func includedColors() -> [String] {
            colors + children.flatMap { $0.includedColors() }
        }

        func includedFonts() -> [String] {
            [font].compactMap { $0 } + children.flatMap { $0.includedFonts() }
        }

    }

    let id = UUID()
    let name: String
    let imageData: Data
    let hierarchy: Node?

    var image: UIImage {
        UIImage(data: imageData) ?? UIImage()
    }

    func includedColors() -> [String] {
        hierarchy?.includedColors() ?? []
    }

    func includedFonts() -> [String] {
        hierarchy?.includedFonts() ?? []
    }
}

extension UIView {
    func capture(name: String) -> Capture? {
        UIGraphicsBeginImageContextWithOptions(frame.size, false, 1)
        defer {
            UIGraphicsEndImageContext()
        }

        layer.render(in: UIGraphicsGetCurrentContext()!)
        guard let imageData = UIGraphicsGetImageFromCurrentImageContext()?.jpegData(compressionQuality: 0.5) else { return nil }

        return Capture(
            name: name,
            imageData: imageData,
            hierarchy: self.asNode()
        )
    }

    private func asNode() -> Capture.Node? {
        let absolutePosition = self.convert(self.bounds, to: nil)

        var children: [Capture.Node] = []
        self.subviews.forEach {
            if !$0.isHidden, let node = $0.asNode() {
                children.append(node)
            }
        }

        var colors: [String] = []
        var font: String?
        if let backgroundColor = backgroundColor {
            colors.append(backgroundColor.hexString)
        }
        if let label = self as? UILabel {
            colors.append(label.textColor.hexString)
            font = label.font.fontName
        }

        return Capture.Node(
            type: "\(type(of: self))",
            absolutePosition: Capture.Position(absolutePosition),
            children: children,
            colors: colors,
            font: font
        )
    }
}

extension UIColor {
    var hexString: String {
        let components = cgColor.components

        let r, g, b: CGFloat
        let a: CGFloat?

        if components?.count == 2 {
            r = components?[safe: 0] ?? 0.0
            g = r
            b = r
            a = components?[safe: 1]
        } else {
            r = components?[safe: 0] ?? 0.0
            g = components?[safe: 1] ?? 0.0
            b = components?[safe: 2] ?? 0.0
            a = components?[safe: 3]
        }

        if let a = a, a != 1.0, a != 0 {
            let hexString = String.init(format: "#%02lX%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)), lroundf(Float(a * 255)))
            return hexString
        } else {
            let hexString = String.init(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
            return hexString
        }
     }

    static func contrastRatio(between color1: UIColor, and color2: UIColor) -> CGFloat {
        // https://www.w3.org/TR/WCAG20-TECHS/G18.html#G18-tests

        let luminance1 = color1.luminance()
        let luminance2 = color2.luminance()

        let luminanceDarker = min(luminance1, luminance2)
        let luminanceLighter = max(luminance1, luminance2)

        return (luminanceLighter + 0.05) / (luminanceDarker + 0.05)
    }

    func contrastRatio(with color: UIColor) -> CGFloat {
        return UIColor.contrastRatio(between: self, and: color)
    }

    func luminance() -> CGFloat {
        // https://www.w3.org/TR/WCAG20-TECHS/G18.html#G18-tests

        let ciColor = CIColor(color: self)

        func adjust(colorComponent: CGFloat) -> CGFloat {
            return (colorComponent < 0.04045) ? (colorComponent / 12.92) : pow((colorComponent + 0.055) / 1.055, 2.4)
        }

        return 0.2126 * adjust(colorComponent: ciColor.red) + 0.7152 * adjust(colorComponent: ciColor.green) + 0.0722 * adjust(colorComponent: ciColor.blue)
    }
}

extension String {
    var isGrayscaleHex: Bool {
        if #available(iOS 16.0, *) {
            return String(prefix(7)).wholeMatch(of: /#([0-9A-Fa-f])([0-9A-Fa-f])((?=\2)\1|(?:\1\2){2})\b/) != nil
        } else {
            return false
        }
    }

    var isSystemFont: Bool {
        hasPrefix("System ")
    }

    var formattedFontName: String {
        if hasPrefix(".SFUI-") {
            return "System Default \(suffix(from: index(startIndex, offsetBy: 6)))"
        } else {
            return self
        }
    }
}

extension Collection {
    func separate(predicate: (Iterator.Element) -> Bool) -> (matching: [Iterator.Element], notMatching: [Iterator.Element]) {
        var groups: ([Iterator.Element], [Iterator.Element]) = ([], [])
        for element in self {
            if predicate(element) {
                groups.0.append(element)
            } else {
                groups.1.append(element)
            }
        }
        return groups
    }
}

extension Array where Element: Hashable {
    func sortedByFrequency() -> [Element] {
        self.reduce(into: [:], { $0[$1, default: 0] += 1 })
        .sorted(by: { $0.value > $1.value })
        .map({ $0.key })
    }
}
