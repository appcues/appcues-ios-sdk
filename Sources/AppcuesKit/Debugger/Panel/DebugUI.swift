//
//  DebugUI.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-29.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

/// Namespaced Views used in the debug panel.
internal enum DebugUI {
    struct MainPanelView: View {

        @ObservedObject var viewModel: DebugViewModel

        var body: some View {
            NavigationView {
                List {
                    Section(header: Text("Status")) {
                        ForEach(viewModel.statusItems) { item in
                            ListItemRowView(item: item)
                        }
                    }

                    Section(header: Text("Recent Events")) {
                        ForEach(viewModel.events.suffix(10).reversed()) { event in
                            NavigationLink(destination: EventDetailView(event: event)) {
                                HStack {
                                    Image(systemName: event.type.symbolName)
                                    Text(event.name)
                                }
                            }
                        }
                    }
                }
                .navigationBarTitle(Text("Debugger"))
                .navigationBarHidden(true)
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

                if let properties = event.eventProperties {
                    Section(header: Text("Properties")) {
                        ForEach(properties, id: \.key) { key, value in
                            EventDetailRowView(title: key, value: value)
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
                 Image(systemName: item.verified ? "checkmark" : "xmark")
                     .foregroundColor(item.verified ? .green : .red )
                     .font(.body.weight(.bold))
                 VStack(alignment: .leading) {
                     Text(item.title)
                     if let subtitle = item.subtitle {
                         Text(subtitle).font(.caption)
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
