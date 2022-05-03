//
//  DebugFontUI.swift
//  AppcuesKit
//
//  Created by Matt on 2022-04-28.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

/// Namespaced Views used in the debug panel.
@available(iOS 13.0, *)
internal enum DebugFontUI {
    enum FontInfo {
        static func allFonts() -> [String] {
            UIFont.familyNames.flatMap {
                UIFont.fontNames(forFamilyName: $0)
            }
        }

        static func systemFonts() -> [String] {
            Font.Design.allCases.flatMap { design in
                Font.Weight.allCases.map { weight in
                    "System \(design.description) \(weight.description)"
                }
            }
        }

        static func appFonts() -> [String] {
            let familyNames: [String] = (Bundle.main.infoDictionary?["UIAppFonts"] as? [String] ?? [])
                .compactMap { resourceName in
                    if let url = Bundle.main.url(forResource: resourceName, withExtension: nil),
                       let fontData = try? Data(contentsOf: url),
                       let fontDataProvider = CGDataProvider(data: fontData as CFData),
                       let font = CGFont(fontDataProvider),
                       let name = font.postScriptName {
                        let ctfont = CTFontCreateWithName(name, 17, nil)
                        return CTFontCopyFamilyName(ctfont) as String
                    } else {
                        return nil
                    }
                }

            return Set(familyNames)
                .sorted()
                .flatMap {
                    UIFont.fontNames(forFamilyName: $0)
                }
        }
    }

    struct FontListView: View {
        private let appFonts = FontInfo.appFonts()
        private let systemFonts = FontInfo.systemFonts()
        private let allFonts = FontInfo.allFonts()

        var sections: [(title: String, names: [String])] {
            var nonEmptySections: [(String, [String])] = []

            let appFonts = filtered(\.appFonts)
            if !appFonts.isEmpty {
                nonEmptySections.append(("App-Specific Fonts", appFonts))
            }

            let systemFonts = filtered(\.systemFonts)
            if !systemFonts.isEmpty {
                nonEmptySections.append(("System Fonts", systemFonts))
            }

            let allFonts = filtered(\.allFonts)
            if !allFonts.isEmpty {
                nonEmptySections.append(("All Fonts", allFonts))
            }

            return nonEmptySections
        }

        @State private var searchText = ""

        var body: some View {
            List {
                ForEach(sections, id: \.title) { title, fonts in
                    Section(header: Text(title)) {
                        ForEach(fonts, id: \.self) {
                            FontItem(name: $0)
                        }
                    }
                }
            }
            .searchableCompatible(text: $searchText)
            .navigationBarTitle("", displayMode: .inline)
        }

        private func filtered(_ key: KeyPath<Self, [String]>) -> [String] {
            let query = searchText.lowercased()
            if query.isEmpty {
                return self[keyPath: key]
            }
            return self[keyPath: key].filter { $0.lowercased().contains(query) }
        }
    }

    private struct FontItem: View {
        let name: String

        var body: some View {
            HStack {
                Text(name)
                    .font(Font(name: name, size: UIFont.labelFontSize))
                Spacer()
                Button {
                    UIPasteboard.general.string = name
                } label: {
                    Image(systemName: "doc.on.doc")
                        .imageScale(.small)
                }
                .foregroundColor(.secondary)
            }
        }
    }

    internal struct Searchable: ViewModifier {
        let text: Binding<String>

        func body(content: Content) -> some View {
            if #available(iOS 15.0, *) {
                content
                    .searchable(text: text)
            } else {
                content
            }
        }
    }
}

@available(iOS 13.0, *)
extension View {
    func searchableCompatible(text: Binding<String>) -> some View {
        modifier(DebugFontUI.Searchable(text: text))
    }
}

@available(iOS 13.0, *)
extension Font.Design: CaseIterable, CustomStringConvertible {
    public static var allCases: [Font.Design] {
        [.default, monospaced, .rounded, .serif]
    }
    public var description: String {
        switch self {
        case .serif: return "Serif"
        case .rounded: return "Rounded"
        case .monospaced: return "Monospaced"
        case .default: fallthrough
        @unknown default: return "Default"
        }
    }
}
@available(iOS 13.0, *)
extension Font.Weight: CaseIterable, CustomStringConvertible {
    public static var allCases: [Font.Weight] {
        [.ultraLight, .thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black]
    }
    public var description: String {
        switch self {
        case .ultraLight: return "Ultralight"
        case .thin: return "Thin"
        case .light: return "Light"
        case .regular: return "Regular"
        case .medium: return "Medium"
        case .semibold: return "Semibold"
        case .bold: return "Bold"
        case .heavy: return "Heavy"
        case .black: return "Black"
        default: return "?"
        }
    }
}
