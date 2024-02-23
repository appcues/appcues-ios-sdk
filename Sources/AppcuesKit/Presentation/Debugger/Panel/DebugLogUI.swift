//
//  DebugLogUI.swift
//  AppcuesKit
//
//  Created by Matt on 2023-10-25.
//  Copyright © 2023 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
internal enum DebugLogUI {
    struct LoggerView: View {
        @EnvironmentObject var logger: DebugLogger

        var body: some View {
            List {
                ForEach(logger.log.suffix(20).reversed()) { log in
                    NavigationLink(destination: DetailView(log: log)) {
                        VStack(alignment: .leading) {
                            Text("\(log.level.description): \(log.timestamp.description)")
                                .fontWeight(.bold)
                            Text(log.message)
                                .lineLimit(10)
                        }
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(log.level.color)
                    }
                }
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(trailing: ShareButton(text: logger.stringEncoded()))
        }
    }

    private struct DetailView: View {
        let log: DebugLogger.Log

        var body: some View {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Level: \(log.level.description)")
                        .fontWeight(.bold)
                    Text("Timestamp: \(log.timestamp.description)")
                        .fontWeight(.bold)
                    Divider()
                    Text(log.message)
                }
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(log.level.color)
                .padding()
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(trailing: ShareButton(text: log.message))
        }
    }

    private struct ShareButton: View {
        let text: String

        var body: some View {
            if #available(iOS 16.0, *) {
                ShareLink(item: text)
            } else {
                Button("Copy Log") {
                    UIPasteboard.general.string = text
                }
            }
        }
    }
}
