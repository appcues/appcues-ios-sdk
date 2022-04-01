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
        return Bundle.module
        #else
        guard let url = Bundle(for: Appcues.self).url(forResource: "Appcues", withExtension: "bundle"),
              let bundle = Bundle(url: url) else {
            fatalError("Can't find 'Appcues' resource bundle")
        }
        return bundle
        #endif
    }()
}
