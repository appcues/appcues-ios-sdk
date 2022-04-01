//
//  URL+Cloudinary.swift
//  AppcuesKit
//
//  Created by Matt on 2021-12-14.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

extension URL {
    /// Map a url with any file extension to one with a `.mp4` file extension.
    ///
    /// This supports a behavior that's specific to Cloudinary.
    func toMP4() -> URL? {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return nil }

        // Find and replace the last occurance of ".ext" in the path
        let options: String.CompareOptions = [.backwards, .caseInsensitive]
        if let range = components.path.range(of: ".\(pathExtension)", options: options, range: nil, locale: nil) {
            components.path = components.path.replacingCharacters(in: range, with: ".mp4")
        }

        return components.url
    }
}
