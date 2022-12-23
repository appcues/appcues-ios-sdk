//
//  DebugTemplateUI.swift
//  AppcuesKit
//
//  Created by Matt on 2022-12-20.
//  Copyright © 2022 Appcues. All rights reserved.
//

import SwiftUI

/// Namespaced Views used in the debug panel.
@available(iOS 16.0, *)
internal enum DebugTemplateUI {
    struct TemplateCaptureView: View {

        @ObservedObject var viewModel: DebugViewModel
        @EnvironmentObject var template: Template

        var body: some View {
            ScrollView {
                VStack(alignment: .leading) {
                    HStack {
                        Button {
                            NotificationCenter.appcues.post(name: .appcuesTemplateCapture, object: self)
                        } label: {
                            Label(
                                viewModel.isAnalyzingForTemplate ? "Stop Analyzing" : "Begin Analyzing",
                                systemImage: viewModel.isAnalyzingForTemplate ? "record.circle.fill" : "record.circle")
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)

                        Spacer()

                        if !template.captures.isEmpty {
                            Button {
                                NotificationCenter.appcues.post(name: .appcuesTemplatePreview, object: self)
                            } label: {
                                HStack {
                                    Image(systemName: "eye.circle")
                                    Text("Preview")
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    if !template.captures.isEmpty {
                        Text("Analyzed Screens")
                            .font(.system(size: 20, weight: .bold))
                        ScrollView(.horizontal) {
                            LazyHStack {
                                ForEach(template.captures.reversed(), id: \.id) { capture in
                                    VStack {
                                        Image(uiImage: capture.image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 80)
                                            .overlay(Rectangle().stroke(lineWidth: 1))
                                        Text(capture.name)
                                            .font(.caption)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                    }
                                    .contextMenu {
                                        Button {
                                            template.removeCapture(capture: capture)
                                        } label: {
                                            Label("Remove", systemImage: "trash")
                                        }
                                    } preview: {
                                        Image(uiImage: capture.image).resizable()
                                    }
                                }
                            }
                            .padding()
                        }
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(8)

                        Text("Components")
                            .font(.system(size: 20, weight: .bold))


                        VStack(spacing: 0) {
                            HeaderTextComponent()
                            BodyTextComponent()
                            PrimaryButtonComponent()
                            SecondaryButtonComponent()
                        }
                        .environmentObject(ExperienceStepViewModel())
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(8)

                        Text("Colors")
                            .font(.system(size: 20, weight: .bold))

                        ScrollView(.horizontal) {
                            LazyHStack {
                                ForEach(template.allColors, id: \.self) {
                                    ColorItem(color: $0)
                                }
                                ForEach(template.allShades, id: \.self) {
                                    ColorItem(color: $0)
                                }
                            }
                            .padding()
                        }
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(8)

                        Text("Fonts")
                            .font(.system(size: 20, weight: .bold))

                        ScrollView(.horizontal) {
                            LazyHStack {
                                ForEach(template.customFonts + template.systemFonts, id: \.self) {
                                    FontItem(name: $0)
                                }
                            }
                            .padding()
                        }
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationBarTitle("", displayMode: .inline)
        }
    }

    private struct ColorItem: View {
        let color: String

        var body: some View {
            ZStack(alignment: .bottom) {
                Color(UIColor(hex: color) ?? .clear)
                    .frame(width: 80, height: 80)
                    .cornerRadius(4)
                Text(color)
                    .font(.caption)
                    .padding(4)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.5))
            }
            .draggable(color)
        }
    }

    private struct FontItem: View {
        let name: String

        var body: some View {
            Text(name)
                .font(Font(name: name, size: UIFont.labelFontSize))
                .frame(width: 80, height: 80)
                .background(Color(uiColor: .tertiarySystemGroupedBackground))
                .cornerRadius(4)
                .draggable(name)
        }
    }

    private struct HeaderTextComponent: View {

        @EnvironmentObject var template: Template

        var body: some View {
            AppcuesText(
                model: ExperienceComponent.TextModel(
                        id: UUID(),
                        text: "Header Text",
                        style: template.headerTextStyle)
            )
            .contextMenu {
                Button {
                    NotificationCenter.appcues.post(name: .appcuesTemplateClone, object: self, userInfo: [ "type": "headerText" ])
                } label: {
                    Label("Match Element in App", systemImage: "eyedropper")
                }
            }
            .dropDestination(for: String.self) { items, _ in
                guard let value = items.first else { return false }

                if value.first == "#" {
                    template.set(component: \.headerTextStyle, property: \.foregroundColor, value: ExperienceComponent.Style.DynamicColor(light: value, dark: nil))
                } else {
                    template.set(component: \.headerTextStyle, property: \.fontName, value: value)
                }
                return true
            }
        }
    }

    private struct BodyTextComponent: View {

        @EnvironmentObject var template: Template

        var body: some View {
            AppcuesText(
                model: ExperienceComponent.TextModel(
                        id: UUID(),
                        text: "Body text",
                        style: template.bodyTextStyle)
            )
            .contextMenu {
                Button {
                    NotificationCenter.appcues.post(name: .appcuesTemplateClone, object: self, userInfo: [ "type": "bodyText" ])
                } label: {
                    Label("Match Element in App", systemImage: "eyedropper")
                }
            }
            .dropDestination(for: String.self) { items, _ in
                guard let value = items.first else { return false }

                if value.first == "#" {
                    template.set(component: \.bodyTextStyle, property: \.foregroundColor, value: ExperienceComponent.Style.DynamicColor(light: value, dark: nil))
                } else {
                    template.set(component: \.bodyTextStyle, property: \.fontName, value: value)
                }
                return true
            }
        }
    }

    private struct PrimaryButtonComponent: View {

        @EnvironmentObject var template: Template

        var body: some View {
            AppcuesButton(
                model: ExperienceComponent.ButtonModel(
                    id: UUID(),
                    content: .text(ExperienceComponent.TextModel(
                        id: UUID(),
                        text: "Primary Button",
                        style: template.primaryButtonTextStyle)),
                    style: template.primaryButtonStyle)
            )
            .contextMenu {
                Button {
                    NotificationCenter.appcues.post(name: .appcuesTemplateClone, object: self, userInfo: [ "type": "primaryButton" ])
                } label: {
                    Label("Match Element in App", systemImage: "eyedropper")
                }
            }
            .dropDestination(for: String.self) { items, _ in
                guard let value = items.first else { return false }

                if value.first == "#" {
                    let colorModel = ExperienceComponent.Style.DynamicColor(light: value, dark: nil)
                    template.set(component: \.primaryButtonStyle, property: \.backgroundColor, value: colorModel)
                    if let color = UIColor(dynamicColor: colorModel) {
                        if UIColor.contrastRatio(between: color, and: .white) > UIColor.contrastRatio(between: color, and: .black) {
                            template.set(component: \.primaryButtonTextStyle, property: \.foregroundColor, value: ExperienceComponent.Style.DynamicColor(light: "#FFFFFF"))
                        } else {
                            template.set(component: \.primaryButtonTextStyle, property: \.foregroundColor, value: ExperienceComponent.Style.DynamicColor(light: "#000000"))
                        }
                    }
                } else {
                    template.set(component: \.primaryButtonTextStyle, property: \.fontName, value: value)
                }
                return true
            }
        }
    }

    private struct SecondaryButtonComponent: View {

        @EnvironmentObject var template: Template

        var body: some View {
            AppcuesButton(
                model: ExperienceComponent.ButtonModel(
                    id: UUID(),
                    content: .text(ExperienceComponent.TextModel(
                        id: UUID(),
                        text: "Secondary Button",
                        style: template.secondaryButtonTextStyle)),
                    style: template.secondaryButtonStyle)
            )
            .contextMenu {
                Button {
                    NotificationCenter.appcues.post(name: .appcuesTemplateClone, object: self, userInfo: [ "type": "secondaryButton" ])
                } label: {
                    Label("Match Element in App", systemImage: "eyedropper")
                }
            }
            .dropDestination(for: String.self) { items, _ in
                guard let value = items.first else { return false }

                if value.first == "#" {
                    template.set(component: \.secondaryButtonStyle, property: \.borderColor, value: ExperienceComponent.Style.DynamicColor(light: value, dark: nil))
                    template.set(component: \.secondaryButtonTextStyle, property: \.foregroundColor, value: ExperienceComponent.Style.DynamicColor(light: value, dark: nil))
                } else {
                    template.set(component: \.secondaryButtonTextStyle, property: \.fontName, value: value)
                }
                return true
            }
        }
    }
}
