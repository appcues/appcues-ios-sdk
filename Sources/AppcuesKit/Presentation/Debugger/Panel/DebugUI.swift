//
//  DebugUI.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-29.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

/// Namespaced Views used in the debug panel.
@available(iOS 13.0, *)
internal enum DebugUI {
    struct MainPanelView: View {

        @ObservedObject var viewModel: DebugViewModel

        var filteredEvents: [DebugViewModel.LoggedEvent] {
            viewModel.events.filter { viewModel.filter == nil || $0.type == viewModel.filter }
        }

        var body: some View {
            NavigationView {
                List {
                    Section(header: Text("Status")) {
                        ForEach(viewModel.statusItems) { item in
                            ListItemRowView(item: item)
                        }
                    }

                    Section(header: Text("Info")) {
                        NavigationLink(destination: DebugFontUI.FontListView(), isActive: $viewModel.navigationDestinationIsFonts) {
                            Text("Available Fonts")
                        }
                    }

                    Section(header: EventsSectionHeader(selection: $viewModel.filter)) {
                        ForEach(filteredEvents.suffix(20).reversed()) { event in
                            NavigationLink(destination: EventDetailView(event: event)) {
                                HStack {
                                    Image(systemName: event.type.symbolName)
                                    Text(event.name)
                                }
                            }
                        }
                    }
                }
                .accentColor(.blue)
                .navigationBarTitle(Text("Debugger"))
                .navigationBarHidden(true)
            }
        }
    }

    private struct EventsSectionHeader: View {
        @Binding var selection: DebugViewModel.LoggedEvent.EventType?

        let options: [DebugViewModel.LoggedEvent.EventType?] = [nil] + DebugViewModel.LoggedEvent.EventType.allCases

        private var title: String {
            if let description = selection?.description {
                return "Recent \(description) Events"
            } else {
                return "All Recent Events"
            }
        }

        var body: some View {
            HStack {
                Text(title)
                Spacer()

                if #available(iOS 14.0, *) {
                    Menu {
                        Picker(selection: $selection, label: Text("Filter")) {
                            ForEach(options, id: \.self) {
                                Label($0?.description ?? "All", systemImage: $0?.symbolName ?? "asterisk")
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                            .font(.body)
                            .labelStyle(.iconOnly)
                    }
                    .textCase(.none)
                }
            }
        }
    }

    private struct EventDetailView: View {
        let event: DebugViewModel.LoggedEvent

        var body: some View {
            List {
                Section(header: Text("Event Details")) {
                    ForEach(event.eventDetailItems, id: \.title) { title, value in
                        EventDetailRowView(title: title, value: value)
                    }
                }

                if let propertyGroups = event.eventProperties {
                    ForEach(propertyGroups, id: \.title) { title, items in
                        Section(header: Text(title)) {
                            ForEach(items, id: \.title) { title, value in
                                EventDetailRowView(title: title, value: value)
                            }
                        }
                    }
                }
            }
            .navigationBarTitle("", displayMode: .inline)
        }
    }

    private struct ListItemRowView: View {
        let item: DebugViewModel.StatusItem

        var body: some View {
             HStack {
                 Image(systemName: item.status.symbolName)
                     .foregroundColor(item.status.tintColor)
                     .font(.body.weight(.bold))
                 VStack(alignment: .leading) {
                     Text(item.title)
                     if let subtitle = item.subtitle {
                         Text(subtitle).font(.caption)
                     }
                 }
                 if let action = item.action {
                     Spacer()
                     Button {
                         action.block()
                     } label: {
                         Image(systemName: action.symbolName)
                             .imageScale(.small)
                     }
                     .foregroundColor(.secondary)
                 }
             }
             .ifLet(item.detailText) { view, detail in
                 view.contextMenu {
                     Button() {
                         UIPasteboard.general.string = detail
                     } label: {
                         HStack {
                             Text("Copy")
                             Spacer()
                             Image(systemName: "doc.on.doc")
                         }
                     }
                 }
             }
        }
    }

    private struct EventDetailRowView: View {
        let title: String
        let value: String?

        var body: some View {
            HStack {
                Text(title)
                if let value = value {
                    Spacer()
                    Text(value)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
    }

}
