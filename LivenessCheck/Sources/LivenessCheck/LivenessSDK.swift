//
//  LivenessSDK.swift
//  LivenessCheck
//
//  Created by Richard Uzor on 08/10/2025.
//

import SwiftUI

public struct LivenessSDK {
    @MainActor @available(macOS 10.15.0, *)
    public static func start(
        sessionId: String,
        region: String,
        config: LivenessUIConfig = .init(),
        onComplete: @escaping (LivenessResult) -> Void
    ) -> some View {
        // ✅ Ensure Amplify is configured internally
              AmplifyInitializer.configureIfNeeded()
              
        return LivenessHostView(
            sessionId: sessionId,
            region: region,
            config: config,
            onComplete: onComplete
        )
    }
}

@available(macOS 10.15, *)
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
