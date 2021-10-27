//
//  UserDefaultWrapper.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/27/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

@propertyWrapper
internal struct UserDefault<T> {
    private let key: String
    private let defaultValue: T

    var wrappedValue: T {
        get {
            return UserDefaults.appcues.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.appcues.set(newValue, forKey: key)
        }
    }

    init(_ key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }
}

extension UserDefaults {
    // swiftlint:disable:next force_unwrapping
    static var appcues = UserDefaults(suiteName: "com.appcues.storage")!
}
