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
                    switch outcome {
                    case .status(let status):
                        if status.caseInsensitiveCompare(LivenessSDK.statusCreated) == .orderedSame {
                            allowed = true
                        } else {
                            onComplete(.failure(LivenessError(
                                code: LivenessError.sessionNotUsableCode,
                                userMessage: "This verification session has already been used or has expired. Please start a new check.",
                                debugMessage: "Gateway reported session status \"\(status)\"; launch requires \"\(LivenessSDK.statusCreated)\""
                            )))
                        }
                    case .gatewayRejected(let httpCode, let gatewayMessage):
                        // The gateway also 400s for sessions that were already
                        // run, so a rejection means "don't open the camera".
                        onComplete(.failure(LivenessError(
                            code: LivenessError.sessionNotUsableCode,
                            userMessage: "This verification session has already been used or has expired. Please start a new check.",
                            debugMessage: "Gateway rejected the status check: HTTP \(httpCode) — \(gatewayMessage ?? "no message")"
                        )))
                    case .unreachable(let detail):
                        onComplete(.failure(LivenessError(
                            code: LivenessError.statusCheckFailedCode,
                            userMessage: "We couldn't verify your session. Please check your internet connection and try again.",
                            debugMessage: "Status check failed before reaching a verdict: \(detail)"
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
