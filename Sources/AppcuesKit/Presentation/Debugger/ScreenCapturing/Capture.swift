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
        let id = UUID()
        // swiftlint:disable:next identifier_name
        let x: CGFloat
        // swiftlint:disable:next identifier_name
        let y: CGFloat
        let width: CGFloat
        let height: CGFloat
        let type: String
        let selector: ElementSelector?
        let children: [View]?
    }

    let id = UUID()
    let applicationId: String
    let displayName: String
    let applicationVersion = Bundle.main.version
    let screenShotImageUrl: URL?
    let deviceModel = UIDevice.current.modelName
    let deviceWidth = UIScreen.main.bounds.size.width
    let deviceHeight = UIScreen.main.bounds.size.height
    let deviceOrientation = UIDevice.current.orientation.isLandscape ? "landscape" : "portrait"
    let deviceType = UIDevice.current.userInterfaceIdiom.analyticsName
    let bundlePackageId = Bundle.main.identifier
    let operatingSystem = "ios"
    let applicationName = Bundle.main.displayName
    let applicationBuild = Bundle.main.build
    let sdkVersion = __appcues_version
    let sdkName = "appcues-ios"
    let osVersion = UIDevice.current.systemVersion
    let layout: View

    // the plan is for this to be sent to a separate endpoint to upload the image, then
    // get back a URL to that image to use for `screenshotImageUrl` in the capture model
    // sent to Appcues
    let screenshot: Data
}

extension Capture: Encodable {
    // to exclude screenshot from encoding
    private enum CodingKeys: String, CodingKey {
        case id
        case applicationId
        case displayName
        case applicationVersion
        case screenShotImageUrl
        case deviceModel
        case deviceWidth
        case deviceHeight
        case deviceOrientation
        case deviceType
        case bundlePackageId
        case operatingSystem
        case applicationName
        case applicationBuild
        case sdkVersion
        case sdkName
        case osVersion
        case layout
    }
}

extension Capture {
    // TODO: just for testing prior to API readiness!
    func prettyPrint() {
        guard
            let data = try? JSONEncoder().encode(self),
            let object = try? JSONSerialization.jsonObject(with: data, options: []),
            let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
            let prettyPrintedString = String(data: data, encoding: .utf8) else { return }
        print(prettyPrintedString)
    }
}
