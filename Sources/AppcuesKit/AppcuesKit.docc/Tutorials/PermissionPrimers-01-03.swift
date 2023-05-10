import AppcuesKit
import AVKit

// ...

let cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
Appcues.shared.identify(
    userID: userID,
    properties: [
        // other user properties...
        "permissionStatusCamera": "\(cameraPermissionStatus.description)"
    ]
)
