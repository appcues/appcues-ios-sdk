//
//  View+AppcuesView.swift
//  AppcuesKit
//
//  Created by Matt on 2023-05-30.
//  Copyright © 2023 Appcues. All rights reserved.
//

import SwiftUI

public extension View {
    /// Associates the view with an identifier for Appcues element targeting.
    /// - Parameter identifier: Unique name identifying the view.
    /// - Returns: A view identifiable by Appcues element targeting.
    func appcuesView(identifier: String?) -> some View {
        self.background(ACTagView(identifier: identifier))
    }
}
