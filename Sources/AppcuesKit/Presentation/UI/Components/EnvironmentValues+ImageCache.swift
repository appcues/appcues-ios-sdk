//
//  EnvironmentValues+ImageCache.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-10.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
internal struct ImageCacheKey: EnvironmentKey {
    // This is mutable so a custom cache can be injected for testing.
    static var defaultValue = SessionImageCache()
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    var imageCache: SessionImageCache {
        get { self[ImageCacheKey.self] }
        set { self[ImageCacheKey.self] = newValue }
    }
}
