//
//  Image+BlurHash.swift
//  AppcuesKit
//
//  Created by Matt on 2022-03-09.
//  Copyright © 2022 Appcues. All rights reserved.
//

import SwiftUI

extension Image {
    init?(blurHash: String?, size: CGSize = CGSize(width: 16, height: 16)) {
        guard let blurHash = blurHash, let image = UIImage(blurHash: blurHash, size: size) else {
            return nil
        }
        self.init(uiImage: image)
    }
}
