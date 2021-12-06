//
//  EmbedWebView.swift
//  AppcuesKit
//
//  Created by James Ellis on 12/1/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation
import SwiftUI
import WebKit

internal struct EmbedWebView: UIViewRepresentable {
    let embed: String

    func makeUIView(context: UIViewRepresentableContext<EmbedWebView>) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true // video plays in its position, not popping open fullscreen
        config.mediaTypesRequiringUserActionForPlayback = [] // for video autoplay

        // the script here is to prevent automatic 8px margins around embed content in the webview
        // swiftlint:disable:next line_length
        let source = "var node = document.createElement(\"style\"); node.innerHTML = \"body { margin:0; }\";document.body.appendChild(node);"
        let script = WKUserScript(
                    source: source,
                    injectionTime: .atDocumentEnd,
                    forMainFrameOnly: false)

        config.userContentController.addUserScript(script)
        let webview = WKWebView(frame: CGRect.zero, configuration: config)
        webview.loadHTMLString(embed, baseURL: nil)
        return webview
    }

    func updateUIView(_ webview: WKWebView, context: UIViewRepresentableContext<EmbedWebView>) {
        webview.loadHTMLString(embed, baseURL: nil)
    }
}
