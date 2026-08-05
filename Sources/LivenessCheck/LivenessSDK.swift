//
//  LivenessSDK.swift
//  LivenessCheck
//
//  Created by Richard Uzor on 08/10/2025.
//

import SwiftUI
import os

extension Logger {
    /// Every SDK failure is logged here; filter with subsystem
    /// `tech.sourceid.LivenessCheck` in Xcode's console or Console.app.
    static let livenessSDK = Logger(subsystem: "tech.sourceid.LivenessCheck", category: "LivenessSDK")
}

public struct LivenessSDK {
    /// Session status required before the capture flow is allowed to start.
    static let statusCreated = "CREATED"

    /// Checks whether a session can be used (gateway status `CREATED`)
    /// without showing any UI. Returns `nil` when the session is usable, or
    /// the `LivenessError` to surface to the user otherwise.
    ///
    /// Call this before presenting the view returned by `start` when you
    /// want nothing on screen at all for a faulty session. If you gate with
    /// this method, pass `apiConfig: nil` to `start` to avoid re-checking.
    public static func checkSession(
        sessionId: String,
        apiConfig: LivenessApiConfig
    ) async -> LivenessError? {
        let outcome = await SessionStatusChecker.fetchStatus(
            apiConfig: apiConfig,
            sessionId: sessionId
        )
        let error = LivenessError.from(outcome: outcome)
        if let error {
            Logger.livenessSDK.error("Session check failed \(error.description, privacy: .public)")
        }
        return error
    }

    /// Entry point for the SourceID liveness check.
    ///
    /// Returns a SwiftUI view hosting the AWS Face Liveness detector for the
    /// given session. The `onComplete` callback fires exactly once with the
    /// outcome. If Amplify cannot be configured, the callback receives the
    /// failure immediately and an empty view is returned.
    ///
    /// When `apiConfig` is provided, the session's status is first verified
    /// against the gateway and the capture flow only starts if the status is
    /// `CREATED`; any other status (already used, expired, ...) is reported
    /// through `onComplete` without opening the camera. When `apiConfig` is
    /// nil the check is skipped and the flow starts directly.
    ///
    /// Failures arrive as `LivenessError`: show `userMessage` to the user,
    /// log `debugMessage` (the SDK already logs it under the
    /// `tech.sourceid.LivenessCheck` subsystem), branch on `code`
    /// programmatically.
    @MainActor
    public static func start(
        sessionId: String,
        region: String = "us-east-1",
        config: LivenessUIConfig = .init(),
        apiConfig: LivenessApiConfig? = nil,
        onComplete: @escaping (LivenessResult) -> Void
    ) -> some View {
        // Central logging: every failure is recorded before the caller sees it.
        let complete: (LivenessResult) -> Void = { result in
            if case .failure(let error) = result {
                Logger.livenessSDK.error("Liveness failed \(error.description, privacy: .public)")
            }
            onComplete(result)
        }

        guard !sessionId.trimmingCharacters(in: .whitespaces).isEmpty else {
            DispatchQueue.main.async {
                complete(.failure(LivenessError(
                    code: LivenessError.invalidArgumentsCode,
                    userMessage: "Verification could not start. Please go back and try again.",
                    debugMessage: "start() called with a blank sessionId"
                )))
            }
            return AnyView(EmptyView())
        }

        do {
            try AmplifyInitializer.configureIfNeeded()
        } catch {
            DispatchQueue.main.async {
                complete(.failure(LivenessError(
                    code: LivenessError.configFailedCode,
                    userMessage: "The verification service could not start. Please try again later.",
                    debugMessage: "Amplify initialization failed: \(error.localizedDescription)"
                )))
            }
            return AnyView(EmptyView())
        }

        guard let apiConfig else {
            return AnyView(
                LivenessHostView(
                    sessionId: sessionId,
                    region: region,
                    config: config,
                    onComplete: complete
                )
            )
        }

        return AnyView(
            LivenessGateView(
                sessionId: sessionId,
                region: region,
                config: config,
                apiConfig: apiConfig,
                onComplete: complete
            )
        )
    }
}

/// Verifies the session status against the gateway before showing the
/// capture flow; shows a themed spinner while the check runs.
private struct LivenessGateView: View {
    let sessionId: String
    let region: String
    let config: LivenessUIConfig
    let apiConfig: LivenessApiConfig
    let onComplete: (LivenessResult) -> Void

    @State private var allowed = false
    @State private var checkStarted = false

    var body: some View {
        Group {
            if allowed {
                LivenessHostView(
                    sessionId: sessionId,
                    region: region,
                    config: config,
                    onComplete: onComplete
                )
            } else {
                ZStack {
                    (config.theme.lowercased() == "dark" ? Color.black : Color.white)
                        .ignoresSafeArea()
                    ProgressView()
                }
            }
        }
        .onAppear {
            guard !checkStarted else { return }
            checkStarted = true
            Task {
                let outcome = await SessionStatusChecker.fetchStatus(
                    apiConfig: apiConfig,
                    sessionId: sessionId
                )
                await MainActor.run {
                    if let error = LivenessError.from(outcome: outcome) {
                        onComplete(.failure(error))
                    } else {
                        allowed = true
                    }
                }
            }
        }
    }
}

private struct LivenessHostView: View {
    let sessionId: String
    let region: String
    let config: LivenessUIConfig
    let onComplete: (LivenessResult) -> Void
    @State private var isPresented = true

    var body: some View {
        FaceLivenessScreen(
            sessionID: sessionId,
            region: region,
            config: config,
            isPresented: $isPresented,
            onCompletion: onComplete
        )
    }
}
