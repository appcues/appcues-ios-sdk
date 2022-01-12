//
//  ExperienceContainerLifecycleHandler.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-17.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal protocol ExperienceContainerLifecycleHandler: AnyObject {
    func containerWillAppear()
    func containerDidAppear()
    func containerWillDisappear()
    func containerDidDisappear()
}
