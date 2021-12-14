//
//  ExperienceComponent.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal protocol ComponentModel {
    var id: UUID { get }
    var style: ExperienceComponent.Style? { get }
}

@dynamicMemberLookup
internal enum ExperienceComponent {
    case pager(PagerModel)
    case stack(StackModel)
    case box(BoxModel)
    case text(TextModel)
    case button(ButtonModel)
    case image(ImageModel)
    case spacer(SpacerModel)

    subscript<T>(dynamicMember keyPath: KeyPath<ComponentModel, T>) -> T {
        switch self {
        case .pager(let model): return model[keyPath: keyPath]
        case .stack(let model): return model[keyPath: keyPath]
        case .box(let model): return model[keyPath: keyPath]
        case .text(let model): return model[keyPath: keyPath]
        case .button(let model): return model[keyPath: keyPath]
        case .image(let model): return model[keyPath: keyPath]
        case .spacer(let model): return model[keyPath: keyPath]
        }
    }
}

extension ExperienceComponent: Identifiable {
    var id: UUID { self[dynamicMember: \.id] }
}

extension ExperienceComponent: Decodable {
    enum CodingKeys: CodingKey {
        case type
        case content
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let modelContainer = try decoder.singleValueContainer()

        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "block":
            self = try container.decode(ExperienceComponent.self, forKey: .content)
        case "pager":
            self = .pager(try modelContainer.decode(PagerModel.self))
        case "stack":
            self = .stack(try modelContainer.decode(StackModel.self))
        case "box":
            self = .box(try modelContainer.decode(BoxModel.self))
        case "text":
            self = .text(try modelContainer.decode(TextModel.self))
        case "button":
            self = .button(try modelContainer.decode(ButtonModel.self))
        case "image":
            self = .image(try modelContainer.decode(ImageModel.self))
        case "spacer":
            self = .spacer(try modelContainer.decode(SpacerModel.self))
        default:
            let context = DecodingError.Context(codingPath: container.codingPath, debugDescription: "unknown type '\(type)'")
            throw DecodingError.valueNotFound(Self.self, context)
        }
    }
}

extension ExperienceComponent {
    struct PagerModel: ComponentModel, Decodable {
        let id: UUID
        let progress: PagerProgressModel
        let items: [ExperienceComponent]

        // Optional properties
        let axis: String?
        // swiftlint:disable:next discouraged_optional_boolean
        let infinite: Bool?

        let style: Style?
    }

    struct PagerProgressModel: Decodable {
        enum IndicatorType: String, Decodable {
            case none
            case dot
        }

        let type: IndicatorType
        let style: Style?
    }

    struct StackModel: ComponentModel, Decodable {
        enum Orientation: String, Decodable {
            case horizontal, vertical
        }
        enum Distribution: String, Decodable {
            case center, equal
        }

        let id: UUID
        let orientation: Orientation
        // distribution is used by horizontal oriented stacks only
        let distribution: Distribution?
        let spacing: Double?
        let items: [ExperienceComponent]

        let style: Style?
    }

    struct BoxModel: ComponentModel, Decodable {
        let id: UUID
        let items: [ExperienceComponent]

        let style: Style?
    }

    struct TextModel: ComponentModel, Decodable {
        let id: UUID
        let text: String

        let style: Style?
    }

    struct ButtonModel: ComponentModel, Decodable {
        let id: UUID
        let text: String

        let style: Style?
    }

    struct ImageModel: ComponentModel, Decodable {

        struct IntrinsicSize: Decodable {
            let width: Double
            let height: Double
        }

        let id: UUID
        let imageUrl: URL?
        // Used to flag an animated gif
        // swiftlint:disable:next discouraged_optional_boolean
        let animated: Bool?
        // Not sure if we'd support this in the builder, but it's handy for previews
        let symbolName: String?
        let contentMode: String?
        let intrinsicSize: IntrinsicSize?

        let style: Style?

        /// URL init
        internal init(imageUrl: URL?, contentMode: String?, intrinsicSize: IntrinsicSize?, style: ExperienceComponent.Style?) {
            self.id = UUID()
            self.imageUrl = imageUrl
            self.animated = nil
            self.symbolName = nil
            self.contentMode = contentMode
            self.intrinsicSize = intrinsicSize
            self.style = style
        }

        /// Symbol init
        internal init(symbolName: String?, style: ExperienceComponent.Style?) {
            self.id = UUID()
            self.imageUrl = nil
            self.animated = nil
            self.symbolName = symbolName
            self.contentMode = "fit"
            self.intrinsicSize = nil
            self.style = style
        }

    }

    struct SpacerModel: ComponentModel, Decodable {
        let id: UUID

        let spacing: Double?

        let style: Style?
    }

    struct Style: Decodable {
        let verticalAlignment: String?
        let horizontalAlignment: String?
        let paddingTop: Double?
        let paddingLeading: Double?
        let paddingBottom: Double?
        let paddingTrailing: Double?
        let marginTop: Double?
        let marginLeading: Double?
        let marginBottom: Double?
        let marginTrailing: Double?
        let height: Double?
        // A value of `-1` signifies "fill width".
        let width: Double?

        let fontName: String?
        let fontSize: Double?
        let fontWeight: String?
        let letterSpacing: Double?
        let lineSpacing: Double?
        let textAlignment: String?
        let foregroundColor: DynamicColor?
        let backgroundColor: DynamicColor?
        let backgroundGradient: RawGradient?
        let shadow: RawShadow?
        let cornerRadius: Double?
        let borderColor: DynamicColor?
        let borderWidth: Double?

        internal init(
            verticalAlignment: String? = nil,
            horizontalAlignment: String? = nil,
            paddingTop: Double? = nil,
            paddingLeading: Double? = nil,
            paddingBottom: Double? = nil,
            paddingTrailing: Double? = nil,
            marginTop: Double? = nil,
            marginLeading: Double? = nil,
            marginBottom: Double? = nil,
            marginTrailing: Double? = nil,
            height: Double? = nil,
            width: Double? = nil,
            fontName: String? = nil,
            fontSize: Double? = nil,
            fontWeight: String? = nil,
            letterSpacing: Double? = nil,
            lineSpacing: Double? = nil,
            textAlignment: String? = nil,
            foregroundColor: DynamicColor? = nil,
            backgroundColor: DynamicColor? = nil,
            backgroundGradient: RawGradient? = nil,
            shadow: RawShadow? = nil,
            cornerRadius: Double? = nil,
            borderColor: DynamicColor? = nil,
            borderWidth: Double? = nil
        ) {
            self.verticalAlignment = verticalAlignment
            self.horizontalAlignment = horizontalAlignment
            self.paddingTop = paddingTop
            self.paddingLeading = paddingLeading
            self.paddingBottom = paddingBottom
            self.paddingTrailing = paddingTrailing
            self.marginTop = marginTop
            self.marginLeading = marginLeading
            self.marginBottom = marginBottom
            self.marginTrailing = marginTrailing
            self.height = height
            self.width = width

            self.fontName = fontName
            self.fontSize = fontSize
            self.fontWeight = fontWeight
            self.letterSpacing = letterSpacing
            self.lineSpacing = lineSpacing
            self.textAlignment = textAlignment
            self.foregroundColor = foregroundColor
            self.backgroundColor = backgroundColor
            self.backgroundGradient = backgroundGradient
            self.shadow = shadow
            self.cornerRadius = cornerRadius
            self.borderColor = borderColor
            self.borderWidth = borderWidth
        }

    }
}

extension ExperienceComponent.Style {

    struct DynamicColor: Decodable, ExpressibleByStringLiteral {
        let light: String
        let dark: String?

        // A hex string maps to light mode only
        init(stringLiteral: String) {
            self.light = stringLiteral
            self.dark = nil
        }
    }

    struct RawGradient: Decodable {
        let colors: [DynamicColor]
        let startPoint: String
        let endPoint: String
    }

    struct RawShadow: Decodable {
        let color: DynamicColor
        let radius: Double
        // swiftlint:disable:next identifier_name
        let x: Double
        // swiftlint:disable:next identifier_name
        let y: Double
    }
}
