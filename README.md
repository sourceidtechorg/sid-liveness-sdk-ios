# SID Liveness SDK (iOS)

The **SourceID Liveness SDK** provides a fast, secure, and customizable way to integrate **face liveness detection** into your iOS application. It wraps the [AWS Amplify Face Liveness](https://ui.docs.amplify.aws/swift/connected-components/liveness) detector (Amazon Rekognition Face Liveness) and adds SourceID session handling, theming, and branding.

---

## Features

* Real-time face liveness detection (AWS Rekognition Face Liveness)
* Customizable UI — theme, title, primary color, branding footer
* Automatic AWS Amplify initialization (no host-app setup required)
* SwiftUI-first API, callable from UIKit via `UIHostingController`
* Guaranteed single completion callback, including configuration failures

---

## Requirements

| Requirement | Version |
| --- | --- |
| **iOS** | 14.0+ |
| **Swift** | 5.9+ |
| **Xcode** | 15+ |

---

## Installation

### Swift Package Manager (recommended)

In Xcode: **File ▸ Add Package Dependencies…** and enter:

```
https://github.com/EQua-Dev/ios-single-liveness-expo.git
```

selecting **Up to Next Major Version** from `1.4.0`. Or in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/EQua-Dev/ios-single-liveness-expo.git", from: "1.4.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "LivenessCheck", package: "ios-single-liveness-expo")
        ]
    )
]
```

> **Note:** the package is currently published from the `EQua-Dev` mirror. Once the official `sourceidtechorg/sid-liveness-sdk-ios` repository is public, swap the URL — the API is identical.

### CocoaPods

**Not currently supported.** The underlying AWS FaceLiveness library is distributed via Swift Package Manager only, and no released CocoaPods version can declare SPM dependencies from a podspec. Use Swift Package Manager. (Do **not** add the `FaceLiveness` pod from the CocoaPods trunk — that is an unrelated third-party SDK by a different vendor.)

### Camera permission

Add to your app's `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>We use the camera to verify that you are a live person.</string>
```

---

## Prerequisite: a liveness session ID

A liveness check runs against a **session** created server-side with Amazon Rekognition (`CreateFaceLivenessSession`). Your backend (e.g. the SourceID gateway's `POST /liveness/generate-liveness-url`) creates the session and returns the `sessionId`; after the flow completes, your backend fetches the confidence result (`GetFaceLivenessSessionResults`).

The SDK **never scores the check itself** — it runs the capture flow. `.success` means the user completed the flow; your backend decides pass/fail from the session results.

---

## Usage

### SwiftUI

```swift
import SwiftUI
import LivenessCheck

struct VerificationScreen: View {
    @State private var showLiveness = false

    var body: some View {
        Button("Start Liveness Check") { showLiveness = true }
            .fullScreenCover(isPresented: $showLiveness) {
                LivenessSDK.start(
                    sessionId: sessionIdFromYourBackend,
                    region: "us-east-1",
                    config: LivenessUIConfig(
                        hideBranding: false,
                        customTitle: "Face Verification",
                        theme: "dark",
                        primaryColorHex: "#0A84FF"
                    )
                ) { result in
                    showLiveness = false
                    switch result {
                    case .success:
                        // Capture flow completed — verify the result server-side.
                        break
                    case .failure(let error):
                        // Configuration failure, cancelled session, network error, ...
                        print(error.localizedDescription)
                    }
                }
            }
    }
}
```

### UIKit

```swift
import UIKit
import SwiftUI
import LivenessCheck

let livenessView = LivenessSDK.start(
    sessionId: sessionIdFromYourBackend,
    region: "us-east-1"
) { [weak self] result in
    self?.presentedViewController?.dismiss(animated: true)
    // Handle result…
}

let host = UIHostingController(rootView: livenessView)
host.modalPresentationStyle = .fullScreen
present(host, animated: true)
```

---

## API

### `LivenessSDK.start(sessionId:region:config:onComplete:) -> some View`

Returns a SwiftUI view hosting the liveness detector. `onComplete` fires exactly once:

| Result | Meaning |
| --- | --- |
| `.success` | The capture flow completed. Verify the session result server-side. |
| `.failure(Error)` | Amplify configuration failed, the user cancelled, the session expired, or a camera/network error occurred. |

### `LivenessUIConfig`

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `hideBranding` | `Bool` | `false` | Hide the "Powered by SourceID" footer |
| `customTitle` | `String?` | `nil` | Title shown above the camera view (omitted when `nil`) |
| `theme` | `String` | `"light"` | `"light"` or `"dark"` |
| `primaryColorHex` | `String?` | `nil` | Accent color, e.g. `"#0A84FF"` (falls back to theme default when nil/invalid) |

---

## AWS configuration

The SDK initializes AWS Amplify (Cognito auth) automatically the first time `LivenessSDK.start` is called — no host-app setup required. Resolution order:

1. If your app already configured Amplify itself, that configuration is reused.
2. If your app bundle contains an `amplifyconfiguration.json`, it is used.
3. Otherwise the SDK falls back to the SourceID default configuration bundled inside the SDK.

---

## Publishing (maintainers)

Releases are consumed straight from git tags via Swift Package Manager:

```bash
# verify it builds first
xcodebuild -scheme LivenessCheck -destination 'generic/platform=iOS Simulator' build
git tag 1.4.0
git push origin 1.4.0                # or the appropriate remote
```

---

## License

MIT © SourceID

## Support

📧 [dev@sourceid.tech](mailto:dev@sourceid.tech) · 🌐 [https://sourceid.tech](https://sourceid.tech)
