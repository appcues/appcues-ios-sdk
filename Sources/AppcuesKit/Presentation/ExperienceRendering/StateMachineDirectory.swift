//
//  StateMachineDirectory.swift
//  AppcuesKit
//
//  Created by Matt on 2023-06-15.
//  Copyright © 2023 Appcues. All rights reserved.
//

import Foundation

internal protocol StateMachineOwning: AnyObject {
    var renderContext: RenderContext? { get set }
    var stateMachine: ExperienceStateMachine? { get set }

    /// Should reset the `stateMachine` to `.idling` and clear any rendered experience without triggering experience analytics.
    func reset()
}

// This class is intended to work like a `Dictionary<RenderContext, StateMachineOwning?>`,
// while abstracting away the fact that it weakly references the value.
internal class StateMachineDirectory {
    private var stateMachines: [RenderContext: WeakStateMachineOwning] = [:]
    private let syncQueue = DispatchQueue(label: "appcues-state-directory")

    func cleanup() {
        // This can safely happen whenever
        syncQueue.async {
            self.stateMachines = self.stateMachines.filter { _, weakRef in weakRef.value != nil }
        }
    }

    func owner(forContext context: RenderContext) -> StateMachineOwning? {
        syncQueue.sync {
            return stateMachines[context]?.value
        }
    }

    func forEach(_ body: ((key: RenderContext, value: StateMachineOwning)) throws -> Void) rethrows {
        // Operate on a copy of the stateMachine dictionary so we don't need to use the syncQueue
        // which would block subsequent uses of the Directory.
        let stateMachineSnapshot = stateMachines

        try stateMachineSnapshot.forEach { renderContext, weakStateMachineOwning in
            if let nonWeakValue = weakStateMachineOwning.value {
                try body((renderContext, nonWeakValue))
            }
        }
    }

    /// Get the `ExperienceStateMachine` associated with the specified key.
    subscript (_ key: RenderContext) -> ExperienceStateMachine? {
        syncQueue.sync {
            return stateMachines[key]?.value?.stateMachine
        }
    }

    subscript (ownerFor key: RenderContext) -> StateMachineOwning? {
        get {
            syncQueue.sync {
                return stateMachines[key]?.value
            }
        }
        set(newValue) {
            syncQueue.sync {
                // Enforce uniqueness (a StateMachineOwning may only be registered for a single RenderContext).
                if let oldRenderContext = newValue?.renderContext, oldRenderContext != key {
                    stateMachines.removeValue(forKey: oldRenderContext)
                }

                stateMachines[key] = WeakStateMachineOwning(newValue)

                // Save the current renderContext so it can be easily removed in the above uniqueness check.
                newValue?.renderContext = key
            }
        }
    }

}

private extension StateMachineDirectory {
    class WeakStateMachineOwning {
        weak var value: StateMachineOwning?

        init (_ wrapping: StateMachineOwning?) { self.value = wrapping }
    }
}
