//
//  Capture.swift
//  AppcuesKit
//
//  Created by Matt on 2022-08-31.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

internal struct Capture: Encodable, Identifiable {
    struct Position: Encodable {
        // swiftlint:disable:next identifier_name
        let x: CGFloat
        // swiftlint:disable:next identifier_name
        let y: CGFloat
        let width: CGFloat
        let height: CGFloat

        init(_ cgRect: CGRect) {
            self.x = cgRect.origin.x
            self.y = cgRect.origin.y
            self.width = cgRect.width
            self.height = cgRect.height
        }
    }
    struct Node: Encodable {
        let type: String
        let selector: ElementSelector
        let absolutePosition: Position
        let children: [Node]
    }

    let id = UUID()
    let imageData: Data
    let hierarchy: Node?

    var image: UIImage {
        UIImage(data: imageData) ?? UIImage()
    }

    var jsonHierarchy: String {
        guard
            let data = try? JSONEncoder().encode(hierarchy),
            let object = try? JSONSerialization.jsonObject(with: data, options: []),
            let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
            let prettyPrintedString = String(data: data, encoding: .utf8) else { return "oops" }

        return prettyPrintedString
    }
}
