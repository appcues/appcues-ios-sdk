//
//  AppcuesNotificationServiceExtension.swift
//  AppcuesNotificationService
//
//  Created by Matt on 2024-03-12.
//  Copyright © 2024 Appcues. All rights reserved.
//

import UserNotifications

/// `UNNotificationServiceExtension` subclass that implements Appcues functionality.
///
/// ## Basic Usage
/// ```swift
/// // In your Notification Service Extension
/// import AppcuesNotificationService
/// class NotificationService: AppcuesNotificationServiceExtension {}
/// ```
open class AppcuesNotificationServiceExtension: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override public func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        if let attachment = request.attachment {
            bestAttemptContent?.attachments = [attachment]
        }

        contentHandler(bestAttemptContent ?? request.content)
    }

    override public func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}

extension UNNotificationRequest {
    var attachment: UNNotificationAttachment? {
        guard let attachment = content.userInfo["appcues_attachment_url"] as? String,
              let attachmentType = content.userInfo["appcues_attachment_type"] as? String,
              let attachmentURL = URL(string: attachment),
              let imageData = try? Data(contentsOf: attachmentURL) else {
            return nil
        }
        return try? UNNotificationAttachment(data: imageData, dataType: attachmentType, options: nil)
    }
}

extension UNNotificationAttachment {
    convenience init(data: Data, dataType: String, options: [NSObject: AnyObject]?) throws {
        let temporaryFolderName = ProcessInfo.processInfo.globallyUniqueString
        let temporaryFolderURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(temporaryFolderName, isDirectory: true)

        try FileManager.default.createDirectory(at: temporaryFolderURL, withIntermediateDirectories: true, attributes: nil)

        let imageFileIdentifier = UUID().uuidString + "." + dataType
        let fileURL = temporaryFolderURL.appendingPathComponent(imageFileIdentifier)

        try data.write(to: fileURL)

        try self.init(identifier: imageFileIdentifier, url: fileURL, options: options)
    }
}
