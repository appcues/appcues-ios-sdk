//
//  MulticastDelegate.swift
//  AppcuesKit
//
//  Created by Matt on 2022-02-11.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

internal class MulticastDelegate<T> {
    private let delegates: NSHashTable<AnyObject> = NSHashTable.weakObjects()

    // Note: delegates.count does not update when weak refs are deallocated
    var isEmpty: Bool {
        delegates.anyObject == nil
    }

    func add(_ delegate: T) {
        delegates.add(delegate as AnyObject)
    }

    func remove(_ delegate: T) {
        delegates.remove(delegate as AnyObject)
    }

    func invoke(_ invocation: (T) -> Void) {
        for delegate in delegates.allObjects {
            // swiftlint:disable:next force_cast
            invocation(delegate as! T)
        }
    }
}
