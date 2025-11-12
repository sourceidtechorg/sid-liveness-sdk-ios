# sid-liveness-sdk-ios

# 🧠 SID Liveness SDK (iOS)

The **SID Liveness SDK for iOS** provides a fast, secure, and customizable way to integrate **face liveness detection** into your iOS application.  
It offers a seamless verification experience powered by **AWS Amplify**, while giving you full control over **UI theme, colors, and branding** — all built with **SwiftUI**.

---

## 🚀 Features

- 🎥 **Real-time face liveness detection**
- 🎨 **Customizable UI** (theme, title, primary color, branding)
- 🧩 **Easy integration** into existing iOS apps
- 🔒 **Secure session handling** via AWS Amplify
- ⚙️ **SwiftUI support** with modern architecture
- 💡 **Lightweight Swift Package** — no manual setup required

---

## 📦 Installation

You can integrate the SDK via **Swift Package Manager (SPM)**.

### Option 1: Add via Xcode
1. In Xcode, go to:
```

File → Add Packages...

```
2. Enter the package URL:
```

[https://github.com/sourceidtechorg/sid-liveness-sdk-ios](https://github.com/sourceidtechorg/sid-liveness-sdk-ios)

````
3. Select the latest version (e.g., `1.0.0`), and add it to your target.

### Option 2: Add manually in `Package.swift`
```swift
dependencies: [
 .package(url: "https://github.com/sourceidtechorg/sid-liveness-sdk-ios", from: "1.0.0")
]
````

Then import it into your Swift code:

```swift
import LivenessCheck
```

---

## ⚙️ SDK Initialization

The SDK automatically handles **AWS Amplify** configuration internally — you don’t need to set up Amplify manually.

Just make sure your app:

* Targets **iOS 14.0** or later
* Has camera permissions configured in `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access for face verification.</string>
```

---

## 🧬 Usage

You can launch the **Liveness Verification Flow** from any SwiftUI View:

```swift
import SwiftUI
import LivenessCheck

struct ContentView: View {
    var body: some View {
        LivenessSDK.start(
            sessionId: "your-session-id-here",
            region: "us-east-1",
            config: LivenessUIConfig(
                hideBranding: true,
                customTitle: "Face Verification",
                theme: .dark,
                primaryColorHex: "#FF5733"
            )
        ) { result in
            switch result {
            case .success(let data):
                print("✅ Liveness check complete: \(data)")
            case .failure(let error):
                print("❌ Liveness check failed: \(error.localizedDescription)")
            }
        }
    }
}
```

---

## 🎨 UI Customization

You can tailor the SDK’s look and feel with the `LivenessUIConfig` struct.

| Property          | Type               | Description                                     |
| ----------------- | ------------------ | ----------------------------------------------- |
| `hideBranding`    | `Bool`             | Hide or show the “Powered by SourceID” footer   |
| `customTitle`     | `String?`          | Custom title displayed at the top of the screen |
| `theme`           | `.light` / `.dark` | Choose between light and dark mode              |
| `primaryColorHex` | `String`           | Set the SDK’s primary/accent color              |

### Example:

```swift
let config = LivenessUIConfig(
    hideBranding: false,
    customTitle: "Verify Your Identity",
    theme: .light,
    primaryColorHex: "#0084FF"
)
```

---

## 🥉 Callbacks

| Callback     | Description                                                    |
| ------------ | -------------------------------------------------------------- |
| `onComplete` | Triggered when the liveness flow finishes successfully         |
| `onError`    | Triggered when there’s a network, session, or permission issue |

### Example:

```swift
LivenessSDK.start(
    sessionId: "example-session-id",
    region: "us-east-1"
) { result in
    switch result {
    case .success:
        print("✅ Verification complete")
    case .failure(let error):
        print("❌ Error: \(error.localizedDescription)")
    }
}
```

---

## 🧪 Permissions

The SDK automatically handles **camera permission requests** at runtime.
If access is denied, it gracefully displays an alert prompting the user to enable camera access.

---

## 📋 Requirements

| Requirement              | Version |
| ------------------------ | ------- |
| iOS                      | 14.0+   |
| macOS                    | 12.0+   |
| Swift                    | 5.9+    |
| AWS Amplify Liveness SDK | 1.4.2+  |
| Xcode                    | 15.0+   |

---

## 🧱 Example Integration (SwiftUI)

```swift
import SwiftUI
import LivenessCheck

@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            Button("Start Liveness Check") {
                // Launch the liveness flow
                LivenessSDK.start(
                    sessionId: "example-session-id",
                    region: "us-east-1",
                    config: LivenessUIConfig(
                        hideBranding: false,
                        customTitle: "Face Liveness Check",
                        theme: .dark,
                        primaryColorHex: "#0A84FF"
                    )
                ) { result in
                    switch result {
                    case .success:
                        print("✅ Verification successful")
                    case .failure(let error):
                        print("❌ Error: \(error)")
                    }
                }
            }
        }
    }
}
```

---

## 🗾 License

```
Copyright (c) 2025 SourceID

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0
```

---

## 💬 Support

For support, integration help, or documentation access:
📧 **[dev@sourceid.tech](mailto:dev@sourceid.tech)**
🌐 **[https://sourceid.tech](https://sourceid.tech)**

```
```

