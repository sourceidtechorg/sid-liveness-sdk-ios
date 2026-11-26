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

/// SourceID developer APIs that create sessions, and the SDK environment matching each.
enum Backend: String, CaseIterable, Identifiable {
    case sbx, rd
    var id: String { rawValue }
    var label: String { self == .sbx ? "Sandbox" : "RD" }
    var sdkEnvironment: String { self == .sbx ? "sandbox" : "development" }
    /// RD is only reachable from devices on the SourceID tailnet.
    var apiBase: String {
        self == .sbx ? "https://api.sbx.sourceid.tech/v1/api" : "https://api-rd.tailfaed50.ts.net/v1/api"
    }
}

/// Test API keys live in this device's Keychain, one per backend, never in code.
enum APIKeyStore {
    private static let service = "tech.sourceid.liveness.tester.api-key"

    static func read(_ backend: Backend) -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: backend.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return "" }
        return String(decoding: data, as: UTF8.self)
    }

    static func write(_ key: String, for backend: Backend) {
        let match: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: backend.rawValue,
        ]
        SecItemDelete(match as CFDictionary)
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var add = match
        add[kSecValueData as String] = Data(trimmed.utf8)
        add[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        SecItemAdd(add as CFDictionary, nil)
    }
}

/// SDK environment choices. "none" skips the gateway calls.
private let environmentChoices = ["none", "sandbox", "development", "production"]

/// Inputs come from the screen or from launch arguments, so a test can be
/// started from the Mac without typing on the phone:
///
///     xcrun devicectl device process launch --console --device <UDID> \
///       tech.sourceid.liveness.tester -- -sessionId <ID> -preset dib -autostart YES
///
/// - `-sessionId <id>`: AWS liveness session id (created server-side).
/// - `-preset standard|dib|dibStart`: look preset.
/// - `-environment none|sandbox|development|production`: the SDK's pre-flight
///   check and post-capture result call (the phone must reach that gateway).
/// - `-backend sbx|rd`: which developer API "New session" calls.
/// - `-apiKey <key>`: test API key for that backend, saved to this device's
///   Keychain (or type it in the app). Never commit keys or build them in.
/// - `-autostart YES`: start the check on launch.
/// - `-AppleLanguages "(ar)"`: run in Arabic to check text overrides and RTL.
struct ContentView: View {
    private static let defaults = UserDefaults.standard

    @State private var sessionId = defaults.string(forKey: "sessionId") ?? ""
    @State private var preset = Preset(rawValue: defaults.string(forKey: "preset") ?? "") ?? .standard
    @State private var environmentName = ContentView.initialEnvironment()
    @State private var backend = Backend(rawValue: defaults.string(forKey: "backend") ?? "") ?? .sbx
    @State private var apiKey = ""
    @State private var fetchingSession = false
    @State private var running = false
    @State private var completed = false
    @State private var results: [String] = []

    private var trimmedSessionId: String { sessionId.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationView {
            Form {
                Section(
                    header: Text("Session"),
                    footer: Text("New session calls the SourceID developer API with the key saved in this phone's Keychain. Test keys only: a real app gets sessions from its server.")
                ) {
                    TextField("Session ID", text: $sessionId)
                        .font(.system(.footnote, design: .monospaced))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Picker("Backend", selection: $backend) {
                        ForEach(Backend.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    SecureField("\(backend.label) API key", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onSubmit { APIKeyStore.write(apiKey, for: backend) }
                    Button(fetchingSession ? "Creating session…" : "New session", action: refreshSession)
                        .disabled(fetchingSession || apiKey.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                Section(header: Text("SDK environment")) {
                    Picker("Environment", selection: $environmentName) {
                        ForEach(environmentChoices, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                Section(header: Text("Look")) {
                    Picker("Preset", selection: $preset) {
                        ForEach(Preset.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                Section {
                    Button("Start liveness check", action: start)
                        .disabled(trimmedSessionId.isEmpty || fetchingSession)
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
                environment: environmentName == "none" ? nil : LivenessEnvironment.fromName(environmentName)
            ) { result in
                DispatchQueue.main.async { finish(with: result) }
            }
        }
        .onChange(of: backend) { newBackend in
            apiKey = APIKeyStore.read(newBackend)
        }
        .onAppear {
            // A -apiKey launch argument is saved to the Keychain for later launches from the home screen.
            if let fromLaunch = UserDefaults.standard.volatileDomain(forName: UserDefaults.argumentDomain)["apiKey"] as? String {
                APIKeyStore.write(fromLaunch, for: backend)
            }
            apiKey = APIKeyStore.read(backend)
            if Self.defaults.bool(forKey: "autostart"), !trimmedSessionId.isEmpty { start() }
        }
    }

    /// Accepts the SDK names and the short backend names (sbx, rd).
    private static func initialEnvironment() -> String {
        switch defaults.string(forKey: "environment")?.lowercased() {
        case "sandbox", "sbx": return "sandbox"
        case "development", "rd", "dev": return "development"
        case "production", "prod": return "production"
        default: return "none"
        }
    }

    /// POST {api}/liveness/generate-liveness-url with the saved key; fills in the new session id.
    private func refreshSession() {
        APIKeyStore.write(apiKey, for: backend)
        guard let url = URL(string: "\(backend.apiBase)/liveness/generate-liveness-url") else { return }
        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue(apiKey.trimmingCharacters(in: .whitespacesAndNewlines), forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = Data("{}".utf8)
        fetchingSession = true
        Task {
            defer { fetchingSession = false }
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let id = (json?["data"] as? [String: Any])?["sessionId"] as? String {
                    sessionId = id
                    environmentName = backend.sdkEnvironment
                    log("NEW SESSION backend=\(backend.rawValue) session=\(id) environment=\(environmentName)")
                } else {
                    let detail = (json?["message"] as? String) ?? String(decoding: data.prefix(200), as: UTF8.self)
                    log("SESSION ERROR HTTP \(status): \(detail)")
                }
            } catch {
                log("SESSION ERROR \(error.localizedDescription)")
            }
        }
    }

    private func start() {
        completed = false
        log("START session=\(trimmedSessionId) preset=\(preset.rawValue) environment=\(environmentName)")
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
