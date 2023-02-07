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

    /// The text value of the component (including any children).
    var textDescription: String? { get }
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
    case optionSelect(OptionSelectModel)
    case textInput(TextInputModel)

    subscript<T>(dynamicMember keyPath: KeyPath<ComponentModel, T>) -> T {
        switch self {
        case .stack(let model): return model[keyPath: keyPath]
        case .box(let model): return model[keyPath: keyPath]
        case .text(let model): return model[keyPath: keyPath]
        case .button(let model): return model[keyPath: keyPath]
        case .image(let model): return model[keyPath: keyPath]
        case .spacer(let model): return model[keyPath: keyPath]
        case .embed(let model): return model[keyPath: keyPath]
        case .optionSelect(let model): return model[keyPath: keyPath]
        case .textInput(let model): return model[keyPath: keyPath]
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
        case "optionSelect":
            self = .optionSelect(try modelContainer.decode(OptionSelectModel.self))
        case "textInput":
            self = .textInput(try modelContainer.decode(TextInputModel.self))
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

        enum StickyEdge: String, Decodable {
            case top, bottom
        }

        let id: UUID
        let orientation: Orientation
        // distribution is used by horizontal oriented stacks only
        let distribution: Distribution?
        let spacing: Double?
        let items: [ExperienceComponent]
        let sticky: StickyEdge?

        let style: Style?

        var textDescription: String? { items.compactMap { $0.textDescription }.joined(separator: " ") }
    }

    struct BoxModel: ComponentModel, Decodable {
        let id: UUID
        let items: [ExperienceComponent]

        let style: Style?

        var textDescription: String? { items.compactMap { $0.textDescription }.joined(separator: " ") }
    }

    struct TextModel: ComponentModel, Decodable {
        let id: UUID
        let text: String

        let style: Style?

        var textDescription: String? { text }
    }

    struct ButtonModel: ComponentModel, Decodable {
        let id: UUID
        let content: ExperienceComponent

        let style: Style?

        var textDescription: String? { content.textDescription }
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

        var textDescription: String? { accessibilityLabel }
    }

    struct EmbedModel: ComponentModel, Decodable {
        let id: UUID
        let embed: String
        let intrinsicSize: IntrinsicSize?
        let style: Style?

        var textDescription: String? { nil }
    }

    struct TextInputModel: ComponentModel, Decodable {
        enum DataType: String, Decodable {
            case text, number, email, phone, name, address, url
        }

        let id: UUID

        let label: TextModel
        let errorLabel: TextModel?
        let placeholder: TextModel?
        let defaultValue: String?
        // swiftlint:disable:next discouraged_optional_boolean
        let required: Bool?
        let numberOfLines: Int?
        let maxLength: Int?
        let dataType: DataType?
        let textFieldStyle: Style?
        let cursorColor: Style.DynamicColor?
        let attributeName: String?

        let style: Style?

        var textDescription: String? { label.textDescription }
    }

    struct FormOptionModel: Decodable, Identifiable {
        var id: String { value }

        let value: String
        let content: ExperienceComponent
        let selectedContent: ExperienceComponent?
    }

    struct OptionSelectModel: ComponentModel, Decodable {
        enum SelectMode: String, Decodable {
            case single, multi
        }

        enum ControlPosition: String, Decodable {
            case leading, trailing, top, bottom, hidden
        }

        enum DisplayFormat: String, Decodable {
            case verticalList, horizontalList, picker, nps
        }

        let id: UUID

        let label: TextModel
        let errorLabel: TextModel?
        let selectMode: SelectMode
        let options: [FormOptionModel]
        let defaultValue: [String]?
        let minSelections: UInt?
        let maxSelections: UInt?
        let controlPosition: ControlPosition?
        let displayFormat: DisplayFormat?
        let selectedColor: Style.DynamicColor?
        let unselectedColor: Style.DynamicColor?
        let accentColor: Style.DynamicColor?
        let pickerStyle: Style?
        let attributeName: String?
        // swiftlint:disable:next discouraged_optional_boolean
        let leadingFill: Bool?

        let style: Style?

        var textDescription: String? { label.textDescription }
    }

    struct SpacerModel: ComponentModel, Decodable {
        let id: UUID
        let spacing: Double?

        let style: Style?

        var textDescription: String? { nil }
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
