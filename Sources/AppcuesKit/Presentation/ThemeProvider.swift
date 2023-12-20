//
//  ThemeProvider.swift
//  AppcuesKit
//
//  Created by Matt on 2023-11-02.
//  Copyright © 2023 Appcues. All rights reserved.
//

import Foundation
import Combine

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
}

@available(iOS 13.0, *)
internal protocol ThemeProviding: AnyObject {
    func theme(id: String?, completion: @escaping (Result<Theme, Error>) -> Void)
    func get(themeID: String?) -> AnyPublisher<Theme?, Never>
}

@available(iOS 13.0, *)
internal class ThemeProvider: ThemeProviding {

    private let config: Appcues.Config
    private let networking: Networking

    var loadedThemes: [String: Theme] = [:]
    private var loadingThemes: [String: AnyPublisher<Theme?, Never>] = [:]

    init(container: DIContainer) {
        self.config = container.resolve(Appcues.Config.self)
        self.networking = container.resolve(Networking.self)
    }

    func get(themeID: String?) -> AnyPublisher<Theme?, Never> {
        print("XXX get theme \(CFAbsoluteTimeGetCurrent())", themeID)
        guard let themeID = themeID else {
            return Result.Publisher(nil).eraseToAnyPublisher()
        }

        if let loadedTheme = loadedThemes[themeID] {
            print("XXX theme cached! \(CFAbsoluteTimeGetCurrent())", loadedTheme)
            return Result.Publisher(loadedTheme).eraseToAnyPublisher()
        }

        if let currentlyFetchingPublisher = loadingThemes[themeID] {
            return currentlyFetchingPublisher.eraseToAnyPublisher()
        }

        let publisher = Future<Theme?, Never> { promise in
            let endpoint = ThemesEndpoint.theme(id: themeID)
            self.networking.get(from: endpoint, authorization: nil) { [weak self] (result: Result<Theme, Error>) in
                switch result {
                case .success(let theme):
                    print("XXX theme loaded! \(CFAbsoluteTimeGetCurrent())", theme)
                    self?.loadedThemes[themeID] = theme
                    promise(.success(theme))
                case .failure(let error):
                    print("XXX theme error", error)
                    promise(.success(nil))
                }
                self?.loadingThemes.removeValue(forKey: themeID)
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()

        loadingThemes[themeID] = publisher

        // Return publisher on main thread to ensure consistency with returning cached data.
        return publisher
    }


    func theme(id: String?, completion: @escaping (Result<Theme, Error>) -> Void) {
        guard let id = id else { return }

        if let theme = loadedThemes[id] {
            completion(.success(theme))
        } else {
            load(themeID: id, completion: completion)
        }
    }

    func load(themeID: String, completion: @escaping (Result<Theme, Error>) -> Void) {
        let endpoint = ThemesEndpoint.theme(id: themeID)

        networking.get(from: endpoint, authorization: nil) { [weak self] (result: Result<Theme, Error>) in
            switch result {
            case .success(let theme):
                self?.loadedThemes[themeID] = theme
                completion(.success(theme))
            case .failure(let error):
                self?.config.logger.error("Loading theme %{public}@ failed with error %{public}@", themeID, "\(error)")
                completion(.failure(error))
            }
        }
    }
}
