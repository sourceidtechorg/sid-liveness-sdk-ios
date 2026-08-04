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
        region: String = "us-east-1",
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

    @State private var showInstructions = true

    public var body: some View {
        if showInstructions {
            LivenessStartView(config: config) { showInstructions = false }
        } else {
            captureView
        }
    }

    private var captureView: some View {
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
                // The SDK shows its own instruction page first.
                disableStartView: true,
                isPresented: $isPresented
            ) { result in
                switch result {
                case .success:
                    onCompletion(.success)
                case .failure(let err):
                    onCompletion(.failure(Self.mapDetectorError(err)))
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

    /// `FaceLivenessDetectionError` renders poorly through
    /// `localizedDescription`; rebuild a readable message from its parts and
    /// map the detector's own cancellation to the documented error.
    private static func mapDetectorError(_ error: Error) -> Error {
        guard let detectorError = error as? FaceLivenessDetectionError else { return error }
        if detectorError == .userCancelled {
            return LivenessCheckError.cancelled
        }
        var message = detectorError.message
        if !detectorError.recoverySuggestion.isEmpty {
            message += " — \(detectorError.recoverySuggestion)"
        }
        return LivenessCheckError.detectorFailure(message)
    }
}
