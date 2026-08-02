//
//  LivenessView.swift
//  LivenessCheck
//

import SwiftUI
import FaceLiveness

public struct FaceLivenessScreen: View {
    let sessionID: String
    let region: String
    let config: LivenessUIConfig
    @Binding var isPresented: Bool
    let onCompletion: (LivenessResult) -> Void

    public init(
        sessionID: String,
        region: String,
        config: LivenessUIConfig,
        isPresented: Binding<Bool>,
        onCompletion: @escaping (LivenessResult) -> Void
    ) {
        self.sessionID = sessionID
        self.region = region
        self.config = config
        self._isPresented = isPresented
        self.onCompletion = onCompletion
    }

    public var body: some View {
        VStack(spacing: 0) {
            if let title = config.customTitle {
                Text(title)
                    .font(.title2.bold())
                    .foregroundColor(config.getPrimaryColor())
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(backgroundColor)
            }

            FaceLivenessDetectorView(
                sessionID: sessionID,
                region: region,
                isPresented: $isPresented
            ) { result in
                switch result {
                case .success:
                    onCompletion(.success)
                case .failure(let err):
                    onCompletion(.failure(err))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if !config.hideBranding {
                HStack {
                    Text("Powered by ")
                        .font(.headline)
                        .foregroundColor(config.getPrimaryColor().opacity(0.6))

                    Image(config.theme.lowercased() == "dark" ? "sid_logo_dark" : "sid_logo_light", bundle: .livenessCheck)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 24)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(backgroundColor)
            }
        }
        .background(backgroundColor.ignoresSafeArea())
    }

    private var backgroundColor: Color {
        config.theme.lowercased() == "dark" ? .black : .white
    }
}
