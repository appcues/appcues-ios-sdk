//
//  BackdropView.swift
//  AppcuesKit
//
//  Created by James Ellis on 4/26/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit

// a special view that can optionally allow a pass-through area poked into it - letting
// touches flow through to underlying views in the application
internal class BackdropView: UIView {

    var touchPassThrough: CGRect?

    // if a touch is on this container view, allow it to flow through to parent controller,
    // to be delegated back to underlying application controller that is presenting the experience
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let touchPassThrough = touchPassThrough else {
            return super.hitTest(point, with: event)
        }

        let shouldReceive = !touchPassThrough.contains(point)
        return shouldReceive ? super.hitTest(point, with: event) : nil
    }
}
