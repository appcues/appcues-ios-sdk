//
//  WebWrapperCell.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-15.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit
import WebKit

/// Show HTML content for a `Flow` step.
///
/// This is a rudimentary temporary implementation until native JSON modal representations are available.
internal class WebWrapperCell: UICollectionViewCell {

    let webView: WKWebView = {
        let view = WKWebView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.scrollView.isScrollEnabled = false
        view.scrollView.alwaysBounceVertical = false
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: contentView.topAnchor),
            webView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }

    func render(html: String, css: String?) {
        let baseHTML = #"""
<html>
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <link href="https://fast.appcues.com/generic/injectable/4.31.30/modal.86669839fbee1b1c78f20b7d496bd3b9de3a2901.css" type="text/css" rel="stylesheet">
        <style type="text/css">appcues{padding:0!important}\#(css ?? "")</style>
    </head>
    <body>
        <appcues class="cue-step-0 active fullscreen">
            <cue class="active full-buttons">
                <section>\#(html)</section>
            </cue>
        </appcues>
    </body>
</html>
"""#

        webView.loadHTMLString(baseHTML, baseURL: URL(string: "https://appcues.com"))
    }
}
