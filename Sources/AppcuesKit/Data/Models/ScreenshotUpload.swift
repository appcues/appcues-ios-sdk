//
//  ScreenshotUpload.swift
//  AppcuesKit
//
//  Created by James Ellis on 2/15/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import Foundation

// response model for the customer API pre-upload-screenshot endpoint
internal struct ScreenshotUpload: Decodable {

    struct Upload: Decodable {
        // the path to PUT image data to for upload, has credentials already included
        let presignedUrl: String
    }

    // the resulting path to the uploaded screenshot to be linked to the screen capture metadata
    let url: String
}
