//
//  AppcuesNotificationServiceExtension.swift
//  AppcuesNotificationService
//
//  Created by Matt on 2024-03-12.
//  Copyright © 2024 Appcues. All rights reserved.
//

import UserNotifications
import UniformTypeIdentifiers
import CoreServices

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

        if let bestAttemptContent = bestAttemptContent {
            processAttachment(bestAttemptContent, contentHandler)
        }
    }

    override public func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

    func processAttachment(_ content: UNMutableNotificationContent, _ contentHandler: @escaping (UNNotificationContent) -> Void) {
        guard let attachment = content.userInfo["appcues_attachment_url"] as? String,
              let attachmentURL = URL(string: attachment) else {
            contentHandler(content)
            return
        }

        let dataTask = URLSession.shared.downloadTask(with: attachmentURL) { url, response, error in
            guard let downloadedURL = url, error == nil else {
                contentHandler(content)
                return
            }

            let temporaryFolderURL = URL(fileURLWithPath: NSTemporaryDirectory())
            let imageFileIdentifier = UUID().uuidString
            let fileType = response?.fileType ?? "tmp"

            let tmpFileURL = temporaryFolderURL
                .appendingPathComponent(imageFileIdentifier)
                .appendingPathExtension(fileType)

            do {
                try FileManager.default.moveItem(at: downloadedURL, to: tmpFileURL)
                let attachment = try UNNotificationAttachment(identifier: imageFileIdentifier, url: tmpFileURL)
                content.attachments = [attachment]
            } catch {
                print(error)
            }

            contentHandler(content)
        }

        dataTask.resume()
    }
}

extension URLResponse {
    var fileType: String? {
        guard let mimeType = self.mimeType else {
            return self.url?.pathExtension
        }

        if #available(iOS 14.0, *) {
            return UTType(mimeType: mimeType)?.preferredFilenameExtension
        } else {
            guard let mimeUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)?.takeUnretainedValue(),
                  let extUTI = UTTypeCopyPreferredTagWithClass(mimeUTI, kUTTagClassFilenameExtension)
                    
            else { return nil }
            return extUTI.takeUnretainedValue() as String
        }
    }
}
