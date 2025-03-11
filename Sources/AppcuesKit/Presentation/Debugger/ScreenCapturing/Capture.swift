//
//  Capture.swift
//  AppcuesKit
//
//  Created by James Ellis on 1/11/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit

internal struct Capture: Identifiable {

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
    let layout: AppcuesViewElement
    let metadata: Metadata
    let timestamp: Date

    // The image data here is sent to a separate endpoint to upload the image, then
    // a URL to that image is returned to use for `screenshotImageUrl` in this capture model
    let screenshot: UIImage

    // Info used on the confirm screen
    let annotatedScreenshot: UIImage
    let targetableElementCount: Int

    internal init(
        appId: String,
        displayName: String,
        screenshotImageUrl: URL?,
        layout: AppcuesViewElement,
        metadata: Capture.Metadata,
        timestamp: Date,
        screenshot: UIImage
    ) {
        self.appId = appId
        self.displayName = displayName
        self.screenshotImageUrl = screenshotImageUrl
        self.layout = layout
        self.metadata = metadata
        self.timestamp = timestamp
        self.screenshot = screenshot

        let targetableRects = layout.targetableRects()
        self.annotatedScreenshot = screenshot.annotate(with: targetableRects)
        self.targetableElementCount = targetableRects.count
    }
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

extension UIImage {
    func annotate(with targetRects: [CGRect]) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: self.size)
        
        return renderer.image { context in
            self.draw(at: CGPoint.zero)

            context.cgContext.setFillColor(UIColor(red: 227 / 255, green: 242 / 255, blue: 255 / 255, alpha: 0.5).cgColor)
            context.cgContext.setStrokeColor(UIColor(red: 20 / 255, green: 146 / 255, blue: 255 / 255, alpha: 1).cgColor)

            context.cgContext.addRects(targetRects)
            context.cgContext.drawPath(using: .fillStroke)
        }
    }
}

extension AppcuesViewElement {
    func targetableRects() -> [CGRect] {
        var targetableRects: [CGRect] = []

        if selector != nil {
            targetableRects.append(CGRect(x: x, y: y, width: width, height: height))
        }

        children?.forEach { child in
            targetableRects.append(contentsOf: child.targetableRects())
        }

        return targetableRects
    }
}
