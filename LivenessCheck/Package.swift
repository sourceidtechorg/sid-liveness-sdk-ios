// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LivenessCheck",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v14),
        .macOS(.v12)
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
            from: "1.4.2"
        ),
    ],
    targets: [
        .target(
            name: "LivenessCheck",
            dependencies: [
                .product(name: "FaceLiveness", package: "amplify-ui-swift-liveness")
            ],
            path: "Sources/LivenessCheck"
        )
    ]
)
