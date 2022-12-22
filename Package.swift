// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Appcues",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "AppcuesKit",
            targets: ["AppcuesKit"]),
    ],
    dependencies: [ ],
    targets: [
        .binaryTarget(name: "GoogleDataTransport", path: "GoogleDataTransport.xcframework"),
        .binaryTarget(name: "GoogleToolboxForMac", path: "GoogleToolboxForMac.xcframework"),
        .binaryTarget(name: "GoogleUtilities", path: "GoogleUtilities.xcframework"),
        .binaryTarget(name: "GoogleUtilitiesComponents", path: "GoogleUtilitiesComponents.xcframework"),
        .binaryTarget(name: "GTMSessionFetcher", path: "GTMSessionFetcher.xcframework"),
        .binaryTarget(name: "FBLPromises", path: "FBLPromises.xcframework"),
        .binaryTarget(name: "nanopb", path: "nanopb.xcframework"),
        .binaryTarget(name: "Protobuf", path: "Protobuf.xcframework"),
        .binaryTarget(name: "SSZipArchive", path: "SSZipArchive.xcframework"),
        .target(
            name: "AppcuesKit",
            dependencies: [
                "GoogleDataTransport",
                "GoogleToolboxForMac",
                "GoogleUtilities",
                "GoogleUtilitiesComponents",
                "GTMSessionFetcher",
                "FBLPromises",
                "nanopb",
                "Protobuf",
                "SSZipArchive",
            ]
        ),
        .testTarget(
            name: "AppcuesKitTests",
            dependencies: ["AppcuesKit"]
        ),
    ]
)
