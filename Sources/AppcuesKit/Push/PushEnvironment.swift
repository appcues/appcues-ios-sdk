//
//  PushEnvironment.swift
//  Appcues
//
//  Created by Matt on 2024-05-21.
//

import UIKit

internal enum PushEnvironment {
    case unknown(Reason)
    case development
    case production

    enum PushEnvironmentError: LocalizedError {
        case noEntitlementsKey
        case noEnvironmentKey
        case unexpectedEnvironment(String)

        var errorDescription: String? {
            switch self {
            case .noEntitlementsKey: return "No 'Entitlements' key"
            case .noEnvironmentKey: return "No entitlement 'aps-environment' key"
            case .unexpectedEnvironment(let value): return "Unexpected 'aps-environment' value '\(value)'"
            }
        }
    }

    enum Reason {
        case notComputed, error(Error)

        var description: String {
            switch self {
            case .notComputed: return "Value not computed"
            case .error(let error): return error.localizedDescription
            }
        }
    }

    var environmentValue: String {
        // The environment to request from the backend must be "development" or "production".
        // If we haven't been able to determine the environment, default to "production".
        switch self {
        case .development: return "development"
        case .unknown, .production: return "production"
        }
    }

    init?(value: String) {
        switch value {
        case "development": self = .development
        case "production": self = .production
        default: return nil
        }
    }
}

extension UIDevice {
    enum ProvisioningProfileError: LocalizedError {
        case noEmbeddedProfile
        case plistScanFailed
        case plistSerializationFailed

        var errorDescription: String? {
            switch self {
            case .noEmbeddedProfile: return "No 'embedded.mobileprovision' found in bundle"
            case .plistScanFailed: return "Property list scan failed"
            case .plistSerializationFailed: return "Property list serialization failed"
            }
        }
    }

    func pushEnvironment() -> PushEnvironment {
    #if targetEnvironment(simulator)
    return .development
    #else
    do {
        let provisioningProfile = try UIDevice.current.provisioningProfile()

        guard let entitlements = provisioningProfile["Entitlements"] as? [String: Any] else {
            return .unknown(.error(PushEnvironment.PushEnvironmentError.noEntitlementsKey))
        }

        guard let environment = entitlements["aps-environment"] as? String else {
            return .unknown(.error(PushEnvironment.PushEnvironmentError.noEnvironmentKey))
        }

        guard let pushEnvironment = PushEnvironment(value: environment) else {
            return .unknown(.error(PushEnvironment.PushEnvironmentError.unexpectedEnvironment(environment)))
        }

        return pushEnvironment
    } catch ProvisioningProfileError.noEmbeddedProfile {
        // App Store apps do not contain an embedded provisioning profile,
        // and since we know we're not on a simulator, that means it's "production".
        return .production
    } catch {
        return .unknown(.error(error))
    }
    #endif
    }

    private func provisioningProfile() throws -> [String: Any] {
        guard let path = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") else {
            throw ProvisioningProfileError.noEmbeddedProfile
        }

        let binaryString = try String(contentsOfFile: path, encoding: .isoLatin1)

        let scanner = Scanner(string: binaryString)
        let plistString: String

        if #available(iOS 13.0, *) {
            guard scanner.scanUpToString("<plist") != nil,
                  let targetString = scanner.scanUpToString("</plist>")
            else {
                throw ProvisioningProfileError.plistScanFailed
            }
            plistString = targetString
        } else {
            // swiftlint:disable:next legacy_objc_type
            var targetString: NSString?

            guard scanner.scanUpTo("<plist", into: nil),
                  scanner.scanUpTo("</plist>", into: &targetString),
                  let targetString = targetString
            else {
                throw ProvisioningProfileError.plistScanFailed
            }
            plistString = targetString as String
        }

        guard let plistData = (plistString + "</plist>").data(using: .isoLatin1) else {
            throw ProvisioningProfileError.plistScanFailed
        }

        guard let serializedPlist = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any]
        else {
            throw ProvisioningProfileError.plistSerializationFailed
        }

        return serializedPlist
    }
}
