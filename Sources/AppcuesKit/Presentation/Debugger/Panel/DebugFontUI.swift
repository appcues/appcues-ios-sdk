//
//  DebugFontUI.swift
//  AppcuesKit
//
//  Created by Matt on 2022-04-28.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
private struct FontInfo {
    struct VariableInfo {
        let range: ClosedRange<Double>
        let initial: Double
    }

    let name: String
    let variableInfo: VariableInfo?

    init(name: String, variableInfo: FontInfo.VariableInfo? = nil) {
        self.name = name
        self.variableInfo = variableInfo
    }
}

/// Namespaced Views used in the debug panel.
@available(iOS 13.0, *)
internal enum DebugFontUI {
    struct FontListView: View {
        private let appFonts: [FontInfo] = FontInfo.appFonts()
        private let systemFonts: [FontInfo] = FontInfo.systemFonts()
        private let allFonts: [FontInfo] = FontInfo.allFonts()

        var body: some View {
            List {
                Section(header: Text("App-Specific Fonts")) {
                    ForEach(appFonts, id: \.name) {
                        FontItem(fontInfo: $0)
                    }
                }

                Section(header: Text("System Fonts")) {
                    ForEach(systemFonts, id: \.name) {
                        FontItem(fontInfo: $0)
                    }
                }

                Section(header: Text("All Fonts")) {
                    ForEach(allFonts, id: \.name) {
                        FontItem(fontInfo: $0)
                    }
                }
            }
            .navigationBarTitle("", displayMode: .inline)
        }
    }

    private struct FontItem: View {
        let fontInfo: FontInfo

        @State private var weight: Double

        var body: some View {
            VStack {
                HStack {
                    if fontInfo.variableInfo != nil {
                        Text("\(fontInfo.name) #\(Int(weight))")
                            .font(Font.custom(fontInfo.name, size: UIFont.labelFontSize, weight: weight))
                    } else {
                        Text(fontInfo.name)
                            .font(Font(name: fontInfo.name, size: UIFont.labelFontSize, weight: nil))
                    }
                    Spacer()
                    Button {
                        if fontInfo.variableInfo != nil {
                            UIPasteboard.general.string = "\(fontInfo.name) #\(Int(weight))"
                        } else {
                            UIPasteboard.general.string = fontInfo.name

                        }
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .imageScale(.small)
                    }
                    .foregroundColor(.secondary)
                }
                if let range = fontInfo.variableInfo?.range {
                    Slider(value: $weight, in: range, step: 1)
                }
            }
        }

        init(fontInfo: FontInfo) {
            self.fontInfo = fontInfo
            self.weight = fontInfo.variableInfo?.initial ?? 0
        }
    }
}

@available(iOS 13.0, *)
extension FontInfo {
    static func allFonts() -> [FontInfo] {
        UIFont.familyNames.flatMap { family in
            UIFont.fontNames(forFamilyName: family)
                .map { FontInfo(name: $0) }
        }
    }

    static func systemFonts() -> [FontInfo] {
        Font.Design.allCases.flatMap { design in
            Font.Weight.allCases.map { weight in
                FontInfo(name: "System \(design.description) \(weight.description)")
            }
        }
    }

    static func appFonts() -> [FontInfo] {
        (Bundle.main.infoDictionary?["UIAppFonts"] as? [String] ?? []).compactMap {
            if let url = Bundle.main.url(forResource: $0, withExtension: nil),
               let fontData = try? Data(contentsOf: url),
               let fontDataProvider = CGDataProvider(data: fontData as CFData),
               let font = CGFont(fontDataProvider),
               let name = font.postScriptName as? String {
                return FontInfo(name: name, variableInfo: font.variableInfo)
            }
            return nil
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

@available(iOS 13.0, *)
fileprivate extension CGFont {
    var variableInfo: FontInfo.VariableInfo? {
        guard let axes = self.variationAxes as? [[String: Any]] else { return nil }

        return axes
            .first { $0[CGFont.variationAxisName as String] as? String == "Weight" }
            .map {
                let min = $0[CGFont.variationAxisMinValue as String] as? Double ?? 100
                let max = $0[CGFont.variationAxisMaxValue as String] as? Double ?? 900
                let initial = $0[CGFont.variationAxisDefaultValue as String] as? Double ?? 400
                return FontInfo.VariableInfo(range: min...max, initial: initial)
            }
    }
}
