//
//  String+Format.swift
//  Appcues
//
//  Created by Matt on 2021-10-12.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

extension String {
    var asURLSlug: String {
        let allowedChars = "0123456789abcdefghijklmnopqrstuvwxyz-"
        return (self.applyingTransform(StringTransform("Any-Latin; Latin-ASCII; Lower;"), reverse: false) ?? "")
                .components(separatedBy: CharacterSet(charactersIn: allowedChars).inverted)
                .filter { !$0.isEmpty }
                .joined(separator: "-")
    }
}
