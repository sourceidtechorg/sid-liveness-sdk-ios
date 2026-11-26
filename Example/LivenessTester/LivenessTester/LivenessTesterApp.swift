import CoreText
import SwiftUI

/// Manual test app for the LivenessCheck SDK, built from this repository's
/// sources. See ../README.md.
@main
struct LivenessTesterApp: App {
    init() {
        BundledFonts.register()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

/// Registers the bundled Exo 2 fonts and remembers their PostScript names,
/// which is what `LivenessFonts` expects on iOS.
enum BundledFonts {
    private(set) static var postScriptNames: [String: String] = [:]

    static func register() {
        let urls = (Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? [])
            + (Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") ?? [])
        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            if let provider = CGDataProvider(url: url as CFURL),
               let font = CGFont(provider),
               let name = font.postScriptName as String? {
                postScriptNames[url.deletingPathExtension().lastPathComponent] = name
            }
        }
        print("LIVENESS_TESTER fonts: \(postScriptNames)")
    }

    static var regular: String? { postScriptNames["Exo2_400Regular"] }
    static var medium: String? { postScriptNames["Exo2_500Medium"] }
    static var bold: String? { postScriptNames["Exo2_700Bold"] }
}
