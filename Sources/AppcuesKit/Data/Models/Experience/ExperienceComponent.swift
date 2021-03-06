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
internal indirect enum ExperienceComponent {
    case stack(StackModel)
    case box(BoxModel)
    case text(TextModel)
    case button(ButtonModel)
    case image(ImageModel)
    case spacer(SpacerModel)
    case embed(EmbedModel)

    subscript<T>(dynamicMember keyPath: KeyPath<ComponentModel, T>) -> T {
        switch self {
        case .stack(let model): return model[keyPath: keyPath]
        case .box(let model): return model[keyPath: keyPath]
        case .text(let model): return model[keyPath: keyPath]
        case .button(let model): return model[keyPath: keyPath]
        case .image(let model): return model[keyPath: keyPath]
        case .spacer(let model): return model[keyPath: keyPath]
        case .embed(let model): return model[keyPath: keyPath]
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
        case "embed":
            self = .embed(try modelContainer.decode(EmbedModel.self))
        default:
            let context = DecodingError.Context(codingPath: container.codingPath, debugDescription: "unknown type '\(type)'")
            throw DecodingError.valueNotFound(Self.self, context)
        }
    }
}

extension ExperienceComponent {
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
        let content: ExperienceComponent

        let style: Style?
    }

    struct ImageModel: ComponentModel, Decodable {
        let id: UUID
        let imageUrl: URL
        let blurHash: String?
        let contentMode: String?
        let intrinsicSize: IntrinsicSize?
        let accessibilityLabel: String?

        let style: Style?

        init(from backgroundImage: Style.BackgroundImage) {
            self.id = UUID()
            self.imageUrl = backgroundImage.imageUrl
            self.blurHash = backgroundImage.blurHash
            self.contentMode = backgroundImage.contentMode
            self.intrinsicSize = backgroundImage.intrinsicSize
            self.accessibilityLabel = nil
            self.style = nil
        }
    }

    struct EmbedModel: ComponentModel, Decodable {
        let id: UUID
        let embed: String
        let intrinsicSize: IntrinsicSize?
        let style: Style?
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
        let letterSpacing: Double?
        let lineHeight: Double?
        let textAlignment: String?
        let foregroundColor: DynamicColor?
        let backgroundColor: DynamicColor?
        let backgroundGradient: RawGradient?
        let backgroundImage: BackgroundImage?
        let shadow: RawShadow?
        let cornerRadius: Double?
        let borderColor: DynamicColor?
        let borderWidth: Double?
    }

    struct IntrinsicSize: Decodable {
        let width: Double
        let height: Double
    }
}

extension ExperienceComponent.Style {

    struct DynamicColor: Decodable {
        let light: String
        let dark: String?
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

    struct BackgroundImage: Decodable {
        let imageUrl: URL
        let blurHash: String?
        let contentMode: String?
        let verticalAlignment: String?
        let horizontalAlignment: String?
        let intrinsicSize: ExperienceComponent.IntrinsicSize?
    }
}
