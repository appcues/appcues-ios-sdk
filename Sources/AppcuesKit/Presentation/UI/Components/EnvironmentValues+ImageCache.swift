//
//  EnvironmentValues+ImageCache.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-10.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

internal struct ImageCacheKey: EnvironmentKey {
    // This is mutable so a custom cache can be injected for testing.
    nonisolated(unsafe) static var defaultValue = SessionImageCache()
}

extension EnvironmentValues {
    var imageCache: SessionImageCache {
        get { self[ImageCacheKey.self] }
        set { self[ImageCacheKey.self] = newValue }
    }
}
