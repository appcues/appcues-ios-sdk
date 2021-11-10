//
//  SessionImageCache.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-10.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

// swiftlint:disable legacy_objc_type
internal struct SessionImageCache {
    private let cache = NSCache<NSURL, UIImage>()

    subscript(_ key: URL) -> UIImage? {
        get { cache.object(forKey: key as NSURL) }
        set {
            if let newValue = newValue {
                cache.setObject(newValue, forKey: key as NSURL)
            } else {
                cache.removeObject(forKey: key as NSURL)
            }
        }
    }
}
