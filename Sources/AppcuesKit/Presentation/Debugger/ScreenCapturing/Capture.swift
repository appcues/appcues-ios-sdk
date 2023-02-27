//
//  Capture.swift
//  AppcuesKit
//
//  Created by James Ellis on 1/11/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit

internal struct Capture: Identifiable {

    struct View: Encodable {
        let id = UUID().appcuesFormatted
        let x: CGFloat
        let y: CGFloat
        let width: CGFloat
        let height: CGFloat
        let type: String
        let selector: ElementSelector?
        let children: [View]?
    }

    struct Metadata: Encodable {
        let appName = Bundle.main.displayName
        let appBuild = Bundle.main.build
        let appVersion = Bundle.main.version
        let deviceModel = UIDevice.current.modelName
        let deviceWidth = UIScreen.main.bounds.size.width
        let deviceHeight = UIScreen.main.bounds.size.height
        let deviceOrientation = UIDevice.current.orientation.isLandscape ? "landscape" : "portrait"
        let deviceType = UIDevice.current.userInterfaceIdiom.analyticsName
        let bundlePackageId = Bundle.main.identifier
        let sdkVersion = __appcues_version
        let sdkName = "appcues-ios"
        let osName = "ios"
        let osVersion = UIDevice.current.systemVersion
        let insets: Insets
    }

    struct Insets: Encodable {
        let left: CGFloat
        let right: CGFloat
        let top: CGFloat
        let bottom: CGFloat

        init(_ insets: UIEdgeInsets) {
            self.left = insets.left
            self.right = insets.right
            self.top = insets.top
            self.bottom = insets.bottom
        }
    }

    let id = UUID().appcuesFormatted
    let appId: String
    var displayName: String
    var screenshotImageUrl: URL?
    let layout: View
    let metadata: Metadata
    let timestamp: Date

    // The image data here is sent to a separate endpoint to upload the image, then
    // a URL to that image is returned to use for `screenshotImageUrl` in this capture model
    let screenshot: UIImage
}

extension Capture: Encodable {
    // to exclude screenshot from encoding
    private enum CodingKeys: String, CodingKey {
        case id
        case appId
        case displayName
        case screenshotImageUrl
        case layout
        case metadata
        case timestamp
    }
}
