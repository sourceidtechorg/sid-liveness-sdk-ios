//
//  LivenessSDK.swift
//  LivenessCheck
//
//  Created by Richard Uzor on 08/10/2025.
//

import SwiftUI

public struct LivenessSDK {
    /// Entry point for the SourceID liveness check.
    ///
    /// Returns a SwiftUI view hosting the AWS Face Liveness detector for the
    /// given session. The `onComplete` callback fires exactly once with the
    /// outcome. If Amplify cannot be configured, the callback receives the
    /// failure immediately and an empty view is returned.
    @MainActor
    public static func start(
        sessionId: String,
        region: String,
        config: LivenessUIConfig = .init(),
        onComplete: @escaping (LivenessResult) -> Void
    ) -> some View {
        do {
            try AmplifyInitializer.configureIfNeeded()
        } catch {
            DispatchQueue.main.async {
                onComplete(.failure(error))
            }
            return AnyView(EmptyView())
        }

        return AnyView(
            LivenessHostView(
                sessionId: sessionId,
                region: region,
                config: config,
                onComplete: onComplete
            )
        )
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
