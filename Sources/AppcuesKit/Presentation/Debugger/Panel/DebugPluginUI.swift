//
//  DebugPluginUI.swift
//  AppcuesKit
//
//  Created by Matt on 2024-10-22.
//  Copyright © 2024 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
internal enum DebugPluginUI {
    struct PluginListView: View {
        let componentDebugInfo: [(identifier: String, debuggableConfig: [String: Any]?)]

        init() {
            self.componentDebugInfo = Appcues.customComponentRegistry.componentDebugInfo
        }

        var body: some View {
            List {
                Section {
                    ForEach(componentDebugInfo, id: \.identifier) { debugInfo in
                        if let debuggableConfig = debugInfo.debuggableConfig {
                            NavigationLink(
                                destination: PluginDetailView(identifier: debugInfo.identifier, debuggableConfig: debuggableConfig)
                            ) {
                                Text(debugInfo.identifier)
                                    .font(Font.system(.body, design: .monospaced))
                            }
                        } else {
                            Text(debugInfo.identifier)
                                .font(Font.system(.body, design: .monospaced))
                        }
                    }
                } header: {
                    Text("Custom Components")
                } footer: {
                    Text("Register custom components with ")
                    + Text("Appcues.registerCustomComponent()").font(Font.system(.caption, design: .monospaced))
                }
            }
            .navigationBarTitle("", displayMode: .inline)
        }
    }

    private struct PluginDetailView: View {
        private let identifier: String
        private let debuggableConfig: [String: Any]
        private let model: ExperienceComponent.CustomComponentModel

        @ObservedObject private var debugActions: DebugAppcuesExperienceActions
        @ObservedObject private var debuggableViewModal: ExperienceStepViewModel
        @State private var showFrame = true

        private var formattedConfig: String {
            debuggableConfig.keys.reduce(into: "") { acc, key in
                let value: String = debuggableConfig[key] is String
                ? "\"\(debuggableConfig[key] ?? "")\""
                : "\(debuggableConfig[key] ?? "")"
                acc += "\n\t\(key)=\(value)"
            }
        }

        init(identifier: String, debuggableConfig: [String: Any]) {
            self.identifier = identifier
            self.debuggableConfig = debuggableConfig

            let viewModel = DebugExperienceViewModel()
            debugActions = viewModel.debugActions
            debuggableViewModal = viewModel

            self.model = ExperienceComponent.CustomComponentModel(
                id: UUID(),
                identifier: identifier,
                configDecoder: DebuggableDecoder(properties: debuggableConfig),
                style: nil
            )
        }

        var body: some View {
            ScrollView {
                VStack(alignment: .leading) {
                    ScrollView(.horizontal) {
                        Text("<\(identifier)\(formattedConfig)\n/>")
                            .font(.system(.body, design: .monospaced))
                            .padding()
                    }

                    VStack(alignment: .leading) {
                        AppcuesCustomComponent(model: model)
                            .environmentObject(debuggableViewModal)
                            .border(showFrame ? Color.appcuesBlurple : Color.clear)

                        Toggle("Show frame", isOn: $showFrame)

                        Text("Actions called:")
                            .font(.system(.headline))
                        Text(debugActions.actionLog)
                    }
                    .padding()
                }
            }
        }
    }
}

@available(iOS 13.0, *)
private extension DebugPluginUI {

    class DebugExperienceViewModel: ExperienceStepViewModel {
        static let renderContext = RenderContext.embed(frameID: "PLUGIN_DEBUG")
        let debugActions = DebugAppcuesExperienceActions(appcues: nil, renderContext: DebugExperienceViewModel.renderContext, identifier: "")

        init() {
            super.init(renderContext: DebugExperienceViewModel.renderContext, appcues: nil)
        }

        override func customComponent(for model: ExperienceComponent.CustomComponentModel) -> CustomComponentData? {
            guard let componentData = super.customComponent(for: model) else { return nil }
            return CustomComponentData(
                type: componentData.type,
                config: componentData.config,
                actionController: debugActions
            )
        }
    }

    class DebugAppcuesExperienceActions: AppcuesExperienceActions, ObservableObject {
        @Published var actionLog: String = ""

        override func triggerBlockActions() {
            actionLog = "triggerBlockActions()\n" + actionLog
        }

        override func track(name: String, properties: [String: Any]? = nil) {
            actionLog = "track(name: \(name), properties: \(properties?.description ?? "nil"))\n" + actionLog
        }

        override func nextStep() {
            actionLog = "nextStep()\n" + actionLog
        }

        override func previousStep() {
            actionLog = "previousStep()\n" + actionLog
        }

        override func close(markComplete: Bool = false) {
            actionLog = "close(markComplete: \(markComplete))\n" + actionLog
        }

        override func updateProfile(properties: [String: Any]) {
            actionLog = "updateProfile(properties: \(properties.description))\n" + actionLog
        }
    }

    class DebuggableDecoder: PluginDecoder {
        let properties: [String: Any]

        init(properties: [String: Any]) {
            self.properties = properties
        }

        func decode<T>(_ type: T.Type) -> T? where T: Decodable {
            guard let data = try? JSONSerialization.data(withJSONObject: properties) else {
                return nil
            }
            return try? JSONDecoder().decode(type, from: data)
        }
    }
}
