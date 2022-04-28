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
                       let name = font.postScriptName as? String {
                        let ctfont = CTFontCreateWithName(name as CFString, 17, nil)
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

        var body: some View {
            List {
                Section(header: Text("App-Specific Fonts")) {
                    ForEach(appFonts, id: \.self) {
                        FontItem(name: $0)
                    }
                }

                Section(header: Text("System Fonts")) {
                    ForEach(systemFonts, id: \.self) {
                        FontItem(name: $0)
                    }
                }

                Section(header: Text("All Fonts")) {
                    ForEach(allFonts, id: \.self) {
                        FontItem(name: $0)
                    }
                }
            }
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
