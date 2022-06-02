//
//  Appcues+ResourceBundle.swift
//  Appcues
//
//  Created by Matt on 2022-01-26.
//

import Foundation

extension Appcues {
    /// Bundle reference used by SwifGen.
    ///
    /// Reference: https://github.com/SwiftGen/SwiftGen/blob/stable/Documentation/Articles/Customize-loading-of-resources.md
    static let resourceBundle: Bundle = {
        #if SWIFT_PACKAGE
        // 1. Swift Package Manager
        return Bundle.module
        #else
        if let url = Bundle(for: Appcues.self).url(forResource: "Appcues", withExtension: "bundle"), let bundle = Bundle(url: url) {
            // 2. Cocoapods
            return bundle
        } else if let bundle = Bundle(identifier: "com.appcues.sdk") {
            // 3. XCFramework
            return bundle
        } else {
            fatalError("Can't find 'Appcues' resource bundle")
        }
        #endif
    }()
}
