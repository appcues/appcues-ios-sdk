//
//  StateMachineDirectory.swift
//  AppcuesKit
//
//  Created by Matt on 2023-06-15.
//  Copyright © 2023 Appcues. All rights reserved.
//

import Foundation

internal protocol StateMachineOwning: AnyObject {
    @available(iOS 13.0, *)
    var stateMachine: ExperienceStateMachine? { get set }
}

// This class is intended to work like a `Dictionary<RenderContext, StateMachineOwning?>`,
// while abstracting away the fact that it weakly references the value.
@available(iOS 13.0, *)
internal class StateMachineDirectory {
    private var stateMachines: [RenderContext: WeakStateMachineOwning] = [:]

    func cleanup() {
        stateMachines = stateMachines.filter { _, weakRef in weakRef.value != nil }
    }

    func owner(forContext context: RenderContext) -> StateMachineOwning? {
        stateMachines[context]?.value
    }

    /// Get the `ExperienceStateMachine` associated with the specified key.
    subscript (_ key: RenderContext) -> ExperienceStateMachine? {
        stateMachines[key]?.value?.stateMachine
    }

    subscript (ownerFor key: RenderContext) -> StateMachineOwning? {
        get {
            stateMachines[key]?.value
        }
        set(newValue) {
            stateMachines[key] = WeakStateMachineOwning(newValue)
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
