//
//  ExperienceComponent.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal struct ExperienceComponent: Identifiable {
    let id: UUID
    let model: ComponentType

    init(model: ExperienceComponent.ComponentType) {
        self.id = UUID()
        self.model = model
    }
}

extension ExperienceComponent: Decodable {
    enum CodingKeys: CodingKey {
        case type
        case id
        case model
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "pager":
            model = .pager(try container.decode(PagerModel.self, forKey: .model))
        case "vstack":
            model = .vstack(try container.decode(VStackModel.self, forKey: .model))
        case "hstack":
            model = .hstack(try container.decode(HStackModel.self, forKey: .model))
        case "zstack":
            model = .zstack(try container.decode(ZStackModel.self, forKey: .model))
        case "text":
            model = .text(try container.decode(TextModel.self, forKey: .model))
        case "button":
            model = .button(try container.decode(ButtonModel.self, forKey: .model))
        case "image":
            model = .image(try container.decode(ImageModel.self, forKey: .model))
        case "spacer":
            model = .spacer(try container.decode(SpacerModel.self, forKey: .model))
        default:
            let context = DecodingError.Context(codingPath: container.codingPath, debugDescription: "unknown type '\(type)'")
            throw DecodingError.valueNotFound(Self.self, context)
        }
    }
}

extension ExperienceComponent {
    enum ComponentType: Decodable {
        case pager(PagerModel)
        case vstack(VStackModel)
        case hstack(HStackModel)
        case zstack(ZStackModel)
        case text(TextModel)
        case button(ButtonModel)
        case image(ImageModel)
        case spacer(SpacerModel)
    }

    struct PagerModel: Decodable {
//        let progress: []
        let items: [ExperienceComponent]

        let layout: Layout?
        let style: Style?
    }

    struct VStackModel: Decodable {
        let items: [ExperienceComponent]

        let layout: Layout?
        let style: Style?
    }

    struct HStackModel: Decodable {
        let items: [ExperienceComponent]

        let layout: Layout?
        let style: Style?
    }

    struct ZStackModel: Decodable {
        let items: [ExperienceComponent]

        let layout: Layout?
        let style: Style?
    }

    struct TextModel: Decodable {
        let text: String

        let layout: Layout?
        let style: Style?
    }

    struct ButtonModel: Decodable {
        let text: String

        let layout: Layout?
        let style: Style?
    }

    struct ImageModel: Decodable {
        let imageUrl: URL?
        // Not sure if we'd support this in the builder, but it's handy for previews
        let symbolName: String?
        let contentMode: String?

        let layout: Layout?
        let style: Style?

        /// URL init
        internal init(imageUrl: URL?, contentMode: String?, layout: ExperienceComponent.Layout?, style: ExperienceComponent.Style?) {
            self.imageUrl = imageUrl
            self.symbolName = nil
            self.contentMode = contentMode
            self.layout = layout
            self.style = style
        }

        /// Symbol init
        internal init(symbolName: String?, layout: ExperienceComponent.Layout?, style: ExperienceComponent.Style?) {
            self.imageUrl = nil
            self.symbolName = symbolName
            self.contentMode = "fit"
            self.layout = layout
            self.style = style
        }

    }

    struct SpacerModel: Decodable {
        let layout: Layout?
    }

    struct Layout: Decodable {
        let spacing: Double?
        let alignment: String?
        let padding: String?
        let margin: String?
        let height: Double?
        // A value of `-1` signifies "fill width".
        let width: Double?

        internal init(
            spacing: Double? = nil,
            alignment: String? = nil,
            padding: String? = nil,
            margin: String? = nil,
            height: Double? = nil,
            width: Double? = nil
        ) {
            self.spacing = spacing
            self.alignment = alignment
            self.padding = padding
            self.margin = margin
            self.height = height
            self.width = width
        }
    }

    struct Style: Decodable {
        let fontName: String?
        let fontSize: Double?
        let fontWeight: String?
        let lineSpacing: Double?
        let alignment: String?
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
            lineSpacing: Double? = nil,
            alignment: String? = nil,
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
            self.lineSpacing = lineSpacing
            self.alignment = alignment
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
