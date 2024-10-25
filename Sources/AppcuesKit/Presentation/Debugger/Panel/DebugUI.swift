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
        let apiVerifier: APIVerifier
        let deepLinkVerifier: DeepLinkVerifier
        let pushVerifier: PushVerifier

        @ObservedObject var viewModel: DebugViewModel

        @ViewBuilder var statusSection: some View {
            Section(header: Text("Status")) {
                DeviceRow()
                InstalledRow(accountID: viewModel.accountID, applicationID: viewModel.applicationID)
                ConnectedRow(apiVerifier: apiVerifier)
                DeepLinkRow(deepLinkVerifier: deepLinkVerifier)
                PushRow(pushVerifier: pushVerifier)
                ScreensRow(isTrackingScreens: viewModel.trackingPages)
                UserRow(currentUserID: viewModel.currentUserID, isAnonymous: viewModel.isAnonymous)
                GroupRow(currentGroupID: viewModel.currentGroupID)

                ForEach(viewModel.experienceStatuses) { experienceItem in
                    ListItemRowView(item: experienceItem) {
                        // Add a dismiss button to remove error rows.
                        if experienceItem.status == .unverified {
                            Button {
                                viewModel.removeExperienceStatus(id: experienceItem.id)
                            } label: {
                                Image(systemName: "xmark").imageScale(.small)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }

        var body: some View {
            NavigationView {
                List {
                    statusSection

                    Section(header: Text("Info")) {
                        NavigationLink(destination: DebugFontUI.FontListView(), isActive: $viewModel.navigationDestinationIsFonts) {
                            Text("Available Fonts")
                        }
                        NavigationLink(destination: DebugPluginUI.PluginListView(), isActive: $viewModel.navigationDestinationIsPlugins) {
                            Text("Plugins")
                        }
                        NavigationLink(destination: DebugLogUI.LoggerView()) {
                            Text("Detailed Log")
                        }
                    }

                    Section(header: EventsSectionHeader(selection: $viewModel.filter)) {
                        ForEach(viewModel.filteredEvents.suffix(20).reversed()) { event in
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
            .navigationViewStyle(StackNavigationViewStyle())
            .environment(\.layoutDirection, .leftToRight)
        }
    }

    struct DeviceRow: View {
        let statusItem = StatusItem(
            status: .info,
            title: "\(UIDevice.current.modelName) iOS \(UIDevice.current.systemVersion)"
        )

        var body: some View {
            ListItemRowView(item: statusItem)
        }
    }

    struct InstalledRow: View {
        let statusItem: StatusItem

        init(accountID: String, applicationID: String) {
            statusItem = StatusItem(
                status: .verified,
                title: "Installed SDK \(Appcues.version())",
                subtitle: "Account ID: \(accountID)\nApplication ID: \(applicationID)"
            )
        }

        var body: some View {
            ListItemRowView(item: statusItem)
        }
    }

    struct ConnectedRow: View {
        let apiVerifier: APIVerifier

        @State var statusItem = StatusItem(status: .pending, title: "Connected to Appcues")

        var body: some View {
            ListItemRowView(item: statusItem) {
                Button {
                    apiVerifier.verifyAPI()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath").imageScale(.small)
                }
                .foregroundColor(.secondary)
            }
            .onReceive(apiVerifier.publisher) {
                statusItem = $0
            }
        }
    }

    struct DeepLinkRow: View {
        let deepLinkVerifier: DeepLinkVerifier

        @State private var statusItem = StatusItem(status: .pending, title: "Appcues Deep Link", subtitle: "Tap to check configuration")

        var body: some View {
            ListItemRowView(item: statusItem) {
                Button {
                    deepLinkVerifier.verifyDeepLink()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath").imageScale(.small)
                }
                .foregroundColor(.secondary)
            }
            .onReceive(deepLinkVerifier.publisher) {
                statusItem = $0
            }
        }
    }

    struct PushRow: View {
        let pushVerifier: PushVerifier

        @State var statusItem = StatusItem(status: .pending, title: "Push Notifications Configured", subtitle: "Tap to check configuration")

        var body: some View {
            ListItemRowView(item: statusItem) {
                Button {
                    pushVerifier.verifyPush()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath").imageScale(.small)
                }
                .foregroundColor(.secondary)
            }
            .onReceive(pushVerifier.publisher) {
                statusItem = $0
            }
        }
    }

    struct ScreensRow: View {
        let isTrackingScreens: Bool

        var statusItem: StatusItem {
            return StatusItem(
                status: isTrackingScreens ? .verified : .pending,
                title: "Tracking Screens",
                subtitle: isTrackingScreens ? nil : "Navigate to another screen to test"
            )
        }

        var body: some View {
            ListItemRowView(item: statusItem)
        }
    }

    struct UserRow: View {
        let currentUserID: String
        let isAnonymous: Bool

        var statusItem: StatusItem {
            return StatusItem(
                status: currentUserID.isEmpty ? .unverified : .verified,
                title: "User Identified",
                subtitle: !currentUserID.isEmpty && isAnonymous ? "Anonymous User" : currentUserID,
                detailText: currentUserID
            )
        }

        var body: some View {
            ListItemRowView(item: statusItem)
        }
    }

    struct GroupRow: View {
        let currentGroupID: String?

        var statusItem: StatusItem {
            return StatusItem(
                status: currentGroupID == nil ? .pending : .verified,
                title: "Group Identified",
                subtitle: currentGroupID ?? "No group identified",
                detailText: currentGroupID
            )
        }

        var body: some View {
            ListItemRowView(item: statusItem)
        }
    }

    private struct EventsSectionHeader: View {
        @Binding var selection: LoggedEvent.EventType?

        let options: [LoggedEvent.EventType?] = [nil] + LoggedEvent.EventType.allCases

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
        let event: LoggedEvent

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

    struct ListItemRowView<Action: View>: View {
        let item: StatusItem

        var action: () -> Action

        init(item: StatusItem, @ViewBuilder action: @escaping () -> Action) {
            self.item = item
            self.action = action
        }

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
                 Spacer()
                 action()
             }
             .ifLet(item.detailText) { view, detail in
                 view.contextMenu {
                     Button {
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
            }.ifLet(value) { view, value in
                view.contextMenu {
                    Button {
                        UIPasteboard.general.string = value
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

}

@available(iOS 13.0, *)
extension DebugUI.ListItemRowView where Action == EmptyView {
    init(item: StatusItem) {
        self.init(item: item) { EmptyView() }
    }
}
