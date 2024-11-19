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

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true // video plays in its position, not popping open fullscreen
        config.mediaTypesRequiringUserActionForPlayback = [] // for video autoplay

        // the script here is to prevent automatic 8px margins around embed content in the web view
        // swiftlint:disable:next line_length
        let source = "var node = document.createElement(\"style\"); node.innerHTML = \"body { margin:0; }\";document.body.appendChild(node);"
        let script = WKUserScript(
            source: source,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )

        config.userContentController.addUserScript(script)

        let webView = WKWebView(frame: CGRect.zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        // the header here allows the content to scale as expected for a mobile viewport
        // https://stackoverflow.com/a/46000849
        // swiftlint:disable:next line_length
        let headerString = "<head><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'></head>"
        webView.loadHTMLString(headerString + embed, baseURL: nil)

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) { }
}
