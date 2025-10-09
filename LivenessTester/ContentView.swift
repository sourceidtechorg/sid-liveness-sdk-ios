//
//  ContentView.swift
//  LivenessTester
//
//  Created by Richard Uzor on 08/10/2025.
//

import SwiftUI
import LivenessCheck


struct ContentView: View {
    @State private var showLiveness = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Welcome to Liveness Tester")
                .font(.title)
            
            Button("Start Liveness Check") {
                showLiveness.toggle()
            }
            .buttonStyle(.borderedProminent)
        }
        .sheet(isPresented: $showLiveness) {
            // 👇 Invoke your SDK’s public API instead of FaceLivenessScreen directly
            LivenessSDK.start(
                sessionId: "3d87a291-4fba-4065-a0a8-086920fb4618",
                region: "us-east-1",
                config: LivenessUIConfig(
                    hideBranding: false,
                    customTitle: "Verify Your Face",
                    theme: "light",
                    primaryColorHex: "#2D9CDB"
                )
            ) { result in
                // Handle result
                switch result {
                case .success:
                    print("✅ Liveness success")
                case .failure(let error):
                    print("❌ Liveness failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
