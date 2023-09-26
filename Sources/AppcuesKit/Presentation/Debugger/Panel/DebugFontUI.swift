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
    struct FontListView: View {
        let sections: [(title: String, names: [String])]

        private var filteredSections: [(title: String, names: [String])] {
            let query = searchText.lowercased()

            guard !query.isEmpty else { return sections }

            return sections.compactMap { title, names in
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

@available(iOS 13.0, *)
extension View {
    func searchableCompatible(text: Binding<String>) -> some View {
        modifier(DebugFontUI.Searchable(text: text))
    }
}

// These extensions follow the interfaces of `CaseIterable` and `CustomStringConvertible`, but do not conform to those protocols
// so that the extension methods aren't required to be public.

@available(iOS 13.0, *)
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
@available(iOS 13.0, *)
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
