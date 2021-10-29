//
//  DIContainer.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/28/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal class DIContainer {

    // could look into something like SwinjectAutoregistration to make this even
    // simpler to register/resolve
    // reference:
    // https://github.com/Swinject/SwinjectAutoregistration/blob/master/Sources/AutoRegistration.swift

    private var initializers: [String: (DIContainer) -> Any] = [:]
    private var components: [String: Any] = [:]

    func registerLazy<Component>(_ type: Component.Type, initializer: @escaping (DIContainer) -> Component) {
        initializers[String(describing: Component.self)] = initializer
    }

    func registerLazy<Component>(_ type: Component.Type, initializer: @escaping () -> Component) {
        initializers[String(describing: Component.self)] = { _ in initializer() }
    }

    func register<Component>(_ type: Component.Type, value: Component) {
        components[String(describing: Component.self)] = value
    }

    @discardableResult
    func resolve<Component>(_ type: Component.Type) -> Component {
        let key = String(describing: Component.self)
        if let component = components[key] as? Component {
            return component
        }

        if let initializer = initializers[key] {
            // swiftlint:disable:next force_cast
            let component = initializer(self) as! Component
            components[key] = component
            return component
        }

        // this is a coding error, did not register dependency
        fatalError("Unable to resolve type \(key)")
    }
}
