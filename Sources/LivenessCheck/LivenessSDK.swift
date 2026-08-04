//
//  LivenessSDK.swift
//  LivenessCheck
//
//  Created by Richard Uzor on 08/10/2025.
//

import SwiftUI

public struct LivenessSDK {
    /// Session status required before the capture flow is allowed to start.
    static let statusCreated = "CREATED"

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
    @MainActor
    public static func start(
        sessionId: String,
        region: String = "us-east-1",
        config: LivenessUIConfig = .init(),
        apiConfig: LivenessApiConfig? = nil,
        onComplete: @escaping (LivenessResult) -> Void
    ) -> some View {
        guard !sessionId.trimmingCharacters(in: .whitespaces).isEmpty else {
            DispatchQueue.main.async {
                onComplete(.failure(LivenessCheckError.invalidArguments("sessionId is required")))
            }
            return AnyView(EmptyView())
        }

        do {
            try AmplifyInitializer.configureIfNeeded()
        } catch {
            DispatchQueue.main.async {
                onComplete(.failure(error))
            }
            return AnyView(EmptyView())
        }

        guard let apiConfig else {
            return AnyView(
                LivenessHostView(
                    sessionId: sessionId,
                    region: region,
                    config: config,
                    onComplete: onComplete
                )
            )
        }

        return AnyView(
            LivenessGateView(
                sessionId: sessionId,
                region: region,
                config: config,
                apiConfig: apiConfig,
                onComplete: onComplete
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
                do {
                    let status = try await SessionStatusChecker.fetchStatus(
                        apiConfig: apiConfig,
                        sessionId: sessionId
                    )
                    await MainActor.run {
                        if status.caseInsensitiveCompare(LivenessSDK.statusCreated) == .orderedSame {
                            allowed = true
                        } else {
                            onComplete(.failure(LivenessCheckError.sessionNotUsable(
                                "Session cannot be used (status: \(status)). Generate a new session."
                            )))
                        }
                    }
                } catch {
                    // The gateway also 400s for sessions that were already
                    // run, so a failed check means "don't open the camera".
                    let detail = (error as? LivenessCheckError)?.errorDescription
                        ?? error.localizedDescription
                    await MainActor.run {
                        onComplete(.failure(LivenessCheckError.sessionNotUsable(
                            "Session not usable (\(detail)). Generate a new session and try again."
                        )))
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
