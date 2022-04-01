//
//  OSLog+Convenience.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-08.
//  Copyright © 2021 Appcues. All rights reserved.
//

import os.log

// Convenience methods to make the logging call site a bit tidier:
// `logger.error("%{private}s", data)`
// vs
// `os_log("%{private}s", log: .default, type: .error, data)`
//
// This also saves us having to `import os.log` everywhere.
extension OSLog {

    /// Create an appcues-specific logger.
    convenience init(appcuesCategory category: String) {
        self.init(subsystem: "com.appcues.sdk", category: category)
    }

    /// Use this level to capture information that may be useful during development or while troubleshooting a specific problem.
    func debug(_ message: StaticString, _ args: CVarArg...) {
        log(message, type: .debug, args)
    }

    /// Use this level to capture information that may be helpful, but not essential, for troubleshooting errors.
    func info(_ message: StaticString, _ args: CVarArg...) {
        log(message, type: .info, args)
    }

    /// Use this level to capture information about things that might result in a failure.
    func log(_ message: StaticString, _ args: CVarArg...) {
        log(message, type: .default, args)
    }

    /// Use this log level to report process-level errors.
    func error(_ message: StaticString, _ args: CVarArg...) {
        log(message, type: .error, args)
    }

    /// Use this level only to capture system-level or multiprocess information when reporting system errors.
    func fault(_ message: StaticString, _ args: CVarArg...) {
        log(message, type: .fault, args)
    }

    private func log(_ message: StaticString, type: OSLogType, _ args: [CVarArg]) {
        // Swift doesn't support splatting so unfortunately `args` needs to be manually enumerated.
        // Limiting it to 5 since that seems reasonable.
        guard args.count <= 5 else {
            assertionFailure("Too many log args. 5 are supported, \(args.count) passed.")
            return
        }

        switch args.count {
        case 1:
            os_log(message, log: self, type: type, args[0])
        case 2:
            os_log(message, log: self, type: type, args[0], args[1])
        case 3:
            os_log(message, log: self, type: type, args[0], args[1], args[2])
        case 4:
            os_log(message, log: self, type: type, args[0], args[1], args[2], args[3])
        case 5:
            os_log(message, log: self, type: type, args[0], args[1], args[2], args[3], args[4])
        default:
            os_log(message, log: self, type: type)
        }
    }
}
