//
//  ExperienceStepLifecycleHandler.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-17.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal protocol ExperienceStepLifecycleHandler: AnyObject {
    func stepWillAppear()
    func stepDidAppear()
    func stepWillDisappear()
    func stepDidDisappear()
}
