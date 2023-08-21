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
    @available(iOS 13.0, *)
    var stateMachine: ExperienceStateMachine? { get set }
}

// This class is intended to work like a `Dictionary<RenderContext, StateMachineOwning?>`,
// while abstracting away the fact that it weakly references the value.
@available(iOS 13.0, *)
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

@available(iOS 13.0, *)
private extension StateMachineDirectory {
    class WeakStateMachineOwning {
        weak var value: StateMachineOwning?

        init (_ wrapping: StateMachineOwning?) { self.value = wrapping }
    }
}
