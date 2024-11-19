//
//  DebugFontUI.swift
//  AppcuesKit
//
//  Created by Matt on 2022-04-28.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

/// Namespaced Views used in the debug panel.
internal enum DebugFontUI {
    struct FontListView: View {
        static let sections: [(title: String, names: [String])] = {
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

            let appFonts = Set(familyNames).sorted().flatMap { UIFont.fontNames(forFamilyName: $0) }
            let systemFonts = Font.Design.allCases.flatMap { design in
                Font.Weight.allCases.map { weight in
                    "System \(design.description) \(weight.description)"
                }
            }
            let allFonts = UIFont.familyNames.flatMap { UIFont.fontNames(forFamilyName: $0) }

            return [
                ("App-Specific Fonts", appFonts),
                ("System Fonts", systemFonts),
                ("All Fonts", allFonts)
            ]
        }()

        private var filteredSections: [(title: String, names: [String])] {
            let query = searchText.lowercased()

            guard !query.isEmpty else { return FontListView.sections }

            return FontListView.sections.compactMap { title, names in
                let filteredNames = names.filter { $0.lowercased().contains(query) }
                if !filteredNames.isEmpty {
                    return (title, filteredNames)
                } else {
                    return nil
                }
            }
        }

        @State private var searchText = ""

        var body: some View {
            List {
                ForEach(filteredSections, id: \.title) { title, fonts in
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

extension View {
    func searchableCompatible(text: Binding<String>) -> some View {
        modifier(DebugFontUI.Searchable(text: text))
    }
}

// These extensions follow the interfaces of `CaseIterable` and `CustomStringConvertible`, but do not conform to those protocols
// so that the extension methods aren't required to be public.

extension Font.Design {
    static var allCases: [Font.Design] {
        [.default, monospaced, .rounded, .serif]
    }
    var description: String {
        switch self {
        case .serif: return "Serif"
        case .rounded: return "Rounded"
        case .monospaced: return "Monospaced"
        case .default: fallthrough
        @unknown default: return "Default"
        }
    }
}
extension Font.Weight {
    static var allCases: [Font.Weight] {
        [.ultraLight, .thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black]
    }
    var description: String {
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
