//
//  SessionImageCache.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-10.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

// swiftlint:disable legacy_objc_type
internal class SessionImageCache {
    private let imageCache = NSCache<NSURL, UIImage>()
    private let animatedImageCache = NSCache<NSURL, NSData>()

    subscript(_ key: URL) -> UIImage? {
        get { imageCache.object(forKey: key as NSURL) }
        set {
            if let newValue = newValue {
                imageCache.setObject(newValue, forKey: key as NSURL)
            } else {
                imageCache.removeObject(forKey: key as NSURL)
            }
        }
    }

    subscript(_ key: URL) -> FLAnimatedImage? {
        get {
            if let data = animatedImageCache.object(forKey: key as NSURL) as Data? {
                return FLAnimatedImage(data: data)
            }
            return nil
        }
        set {
            if let newValue = newValue {
                animatedImageCache.setObject(newValue.data as NSData, forKey: key as NSURL)
            } else {
                animatedImageCache.removeObject(forKey: key as NSURL)
            }
        }
    }

}
