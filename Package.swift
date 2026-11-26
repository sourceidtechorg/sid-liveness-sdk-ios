// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LivenessCheck",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(
            name: "LivenessCheck",
            targets: ["LivenessCheck"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/aws-amplify/amplify-ui-swift-liveness.git",
            from: "1.6.0"
        ),
        // Force a newer version of swift-log that's compatible with Swift 5.9
              .package(
                  url: "https://github.com/apple/swift-log.git",
                  from: "1.6.4" // This version fixes the @inlinable issue
              ),
    ],
    targets: [
        .target(
            name: "LivenessCheck",
            dependencies: [
                .product(name: "FaceLiveness", package: "amplify-ui-swift-liveness"),
                .product(name: "Logging", package: "swift-log"),

            ],
            path: "Sources/LivenessCheck",
            resources: [
                .copy("Resources/amplifyconfiguration.json")
            ]
        )
    ]
)
