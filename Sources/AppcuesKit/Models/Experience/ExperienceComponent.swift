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
    var layout: ExperienceComponent.Layout? { get }
    var style: ExperienceComponent.Style? { get }
}

@dynamicMemberLookup
internal enum ExperienceComponent {
    case pager(PagerModel)
    case vstack(VStackModel)
    case hstack(HStackModel)
    case zstack(ZStackModel)
    case text(TextModel)
    case button(ButtonModel)
    case image(ImageModel)
    case spacer(SpacerModel)

    subscript<T>(dynamicMember keyPath: KeyPath<ComponentModel, T>) -> T {
        switch self {
        case .pager(let model): return model[keyPath: keyPath]
        case .vstack(let model): return model[keyPath: keyPath]
        case .hstack(let model): return model[keyPath: keyPath]
        case .zstack(let model): return model[keyPath: keyPath]
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
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let modelContainer = try decoder.singleValueContainer()

        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "pager":
            self = .pager(try modelContainer.decode(PagerModel.self))
        case "vstack":
            self = .vstack(try modelContainer.decode(VStackModel.self))
        case "hstack":
            self = .hstack(try modelContainer.decode(HStackModel.self))
        case "zstack":
            self = .zstack(try modelContainer.decode(ZStackModel.self))
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
//        let progress: []
        let items: [ExperienceComponent]

        let layout: Layout?
        let style: Style?
    }

    struct VStackModel: ComponentModel, Decodable {
        let id: UUID
        let items: [ExperienceComponent]

        let layout: Layout?
        let style: Style?
    }

    struct HStackModel: ComponentModel, Decodable {
        let id: UUID
        let items: [ExperienceComponent]

        let layout: Layout?
        let style: Style?
    }

    struct ZStackModel: ComponentModel, Decodable {
        let id: UUID
        let items: [ExperienceComponent]

        let layout: Layout?
        let style: Style?
    }

    struct TextModel: ComponentModel, Decodable {
        let id: UUID
        let text: String

        let layout: Layout?
        let style: Style?
    }

    struct ButtonModel: ComponentModel, Decodable {
        let id: UUID
        let text: String

        let layout: Layout?
        let style: Style?
    }

    struct ImageModel: ComponentModel, Decodable {
        let id: UUID
        let imageUrl: URL?
        // Not sure if we'd support this in the builder, but it's handy for previews
        let symbolName: String?
        let contentMode: String?

        let layout: Layout?
        let style: Style?

        /// URL init
        internal init(imageUrl: URL?, contentMode: String?, layout: ExperienceComponent.Layout?, style: ExperienceComponent.Style?) {
            self.id = UUID()
            self.imageUrl = imageUrl
            self.symbolName = nil
            self.contentMode = contentMode
            self.layout = layout
            self.style = style
        }

        /// Symbol init
        internal init(symbolName: String?, layout: ExperienceComponent.Layout?, style: ExperienceComponent.Style?) {
            self.id = UUID()
            self.imageUrl = nil
            self.symbolName = symbolName
            self.contentMode = "fit"
            self.layout = layout
            self.style = style
        }

    }

    struct SpacerModel: ComponentModel, Decodable {
        let id: UUID
        let layout: Layout?
        let style: Style?
    }

    struct Layout: Decodable {
        let spacing: Double?
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

        internal init(
            spacing: Double? = nil,
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
            width: Double? = nil
        ) {
            self.spacing = spacing
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
        }
    }

    struct Style: Decodable {
        let fontName: String?
        let fontSize: Double?
        let fontWeight: String?
        let letterSpacing: Double?
        let lineSpacing: Double?
        let textAlignment: String?
        let foregroundColor: String?
        let backgroundColor: String?
        let backgroundGradient: RawGradient?
        let cornerRadius: Double?
        let borderColor: String?
        let borderWidth: Double?

        internal init(
            fontName: String? = nil,
            fontSize: Double? = nil,
            fontWeight: String? = nil,
            letterSpacing: Double? = nil,
            lineSpacing: Double? = nil,
            textAlignment: String? = nil,
            foregroundColor: String? = nil,
            backgroundColor: String? = nil,
            backgroundGradient: RawGradient? = nil,
            cornerRadius: Double? = nil,
            borderColor: String? = nil,
            borderWidth: Double? = nil
        ) {
            self.fontName = fontName
            self.fontSize = fontSize
            self.fontWeight = fontWeight
            self.letterSpacing = letterSpacing
            self.lineSpacing = lineSpacing
            self.textAlignment = textAlignment
            self.foregroundColor = foregroundColor
            self.backgroundColor = backgroundColor
            self.backgroundGradient = backgroundGradient
            self.cornerRadius = cornerRadius
            self.borderColor = borderColor
            self.borderWidth = borderWidth
        }

    }
}

extension ExperienceComponent.Style {
    struct RawGradient: Decodable {
        let colors: [String]
        let startPoint: String
        let endPoint: String
    }
}
