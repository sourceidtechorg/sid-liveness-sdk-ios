import LivenessCheck
import SwiftUI

/// Look presets covering the 1.9 customisation surface.
enum Preset: String, CaseIterable, Identifiable {
    /// No customisation: the out-of-the-box look.
    case standard
    /// DIB demo: dark green surround, crimson actions, Exo 2, no start page or branding.
    case dib
    /// DIB colours on the light theme with the SourceID start page and branding.
    case dibStart

    var id: String { rawValue }

    var label: String {
        switch self {
        case .standard: return "Default"
        case .dib: return "DIB"
        case .dibStart: return "DIB + start"
        }
    }

    var config: LivenessUIConfig {
        let exo = LivenessFonts(regular: BundledFonts.regular, medium: BundledFonts.medium, bold: BundledFonts.bold)
        switch self {
        case .standard:
            return LivenessUIConfig()
        case .dib:
            return LivenessUIConfig(
                hideBranding: true,
                theme: "dark",
                showStartPage: false,
                colors: LivenessColors(
                    primary: "#AA2236",
                    onPrimary: "#FFFFFF",
                    background: "#0C1F1A",
                    onBackground: "#FFFFFF",
                    surface: "#14302A",
                    error: "#F08A98",
                    onError: "#0C1F1A",
                    errorContainer: "#14302A",
                    onErrorContainer: "#FFFFFF"
                ),
                fonts: exo
            )
        case .dibStart:
            return LivenessUIConfig(
                customTitle: "Verify your identity",
                theme: "light",
                showStartPage: true,
                colors: LivenessColors(
                    primary: "#AA2236",
                    onPrimary: "#FFFFFF",
                    background: "#FFFFFF",
                    onBackground: "#2B2B2B",
                    surface: "#EDF5F1"
                ),
                fonts: exo
            )
        }
    }
}

/// Inputs come from the screen or from launch arguments, so a test can be
/// started from the Mac without typing on the phone:
///
///     xcrun devicectl device process launch --console --device <UDID> \
///       tech.sourceid.liveness.tester -sessionId <ID> -preset dib -autostart YES
///
/// - `-sessionId <id>`: AWS liveness session id (created server-side).
/// - `-preset standard|dib|dibStart`: look preset.
/// - `-environment development|sandbox|production`: enables the SDK's
///   pre-flight check and result fetch (the phone must reach that gateway).
/// - `-autostart YES`: start the check on launch.
/// - `-AppleLanguages "(ar)"`: run in Arabic to check text overrides and RTL.
struct ContentView: View {
    private static let defaults = UserDefaults.standard

    @State private var sessionId = defaults.string(forKey: "sessionId") ?? ""
    @State private var preset = Preset(rawValue: defaults.string(forKey: "preset") ?? "") ?? .standard
    @State private var environmentName = defaults.string(forKey: "environment") ?? ""
    @State private var running = false
    @State private var completed = false
    @State private var results: [String] = []

    private var trimmedSessionId: String { sessionId.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Session")) {
                    TextField("Session ID", text: $sessionId)
                        .font(.system(.footnote, design: .monospaced))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Environment (blank = no gateway calls)", text: $environmentName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                Section(header: Text("Look")) {
                    Picker("Preset", selection: $preset) {
                        ForEach(Preset.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                Section {
                    Button("Start liveness check", action: start)
                        .disabled(trimmedSessionId.isEmpty)
                }
                Section(header: Text("Results, newest first")) {
                    ForEach(Array(results.enumerated().reversed()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(.footnote, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
            }
            .navigationTitle("Liveness tester")
        }
        .navigationViewStyle(.stack)
        .fullScreenCover(isPresented: $running) {
            LivenessSDK.start(
                sessionId: trimmedSessionId,
                config: preset.config,
                environment: LivenessEnvironment.fromName(environmentName.isEmpty ? nil : environmentName)
            ) { result in
                DispatchQueue.main.async { finish(with: result) }
            }
        }
        .onAppear {
            if Self.defaults.bool(forKey: "autostart"), !trimmedSessionId.isEmpty { start() }
        }
    }

    private func start() {
        completed = false
        log("START session=\(trimmedSessionId) preset=\(preset.rawValue) environment=\(environmentName.isEmpty ? "none" : environmentName)")
        running = true
    }

    private func finish(with result: LivenessResult) {
        // The SDK promises one outcome per run; flag any extra so it is visible in testing.
        if completed {
            log("UNEXPECTED second callback: \(describe(result))")
            return
        }
        completed = true
        running = false
        log(describe(result))
    }

    private func describe(_ result: LivenessResult) -> String {
        switch result {
        case .success(let payload):
            if let payload {
                return "SUCCESS status=\(payload.status) confidence=\(payload.confidence.map { String($0) } ?? "-") image=\(payload.referenceImageUrl == nil ? "no" : "yes")"
            }
            return "SUCCESS (capture complete; no gateway result requested)"
        case .failure(let error):
            return "ERROR \(error.code): \(error.userMessage) | \(error.debugMessage)"
        }
    }

    private func log(_ line: String) {
        let stamped = "\(Date().formatted(date: .omitted, time: .standard)) \(line)"
        results.append(stamped)
        print("LIVENESS_TESTER \(stamped)")
    }
}
