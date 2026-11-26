//
//  LivenessView.swift
//  LivenessCheck
//

import AVFoundation
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
        self._showInstructions = State(initialValue: config.showStartPage)
    }

    @State private var showInstructions: Bool
    @State private var cameraReady = false

    public var body: some View {
        if showInstructions {
            LivenessStartView(config: config) { showInstructions = false }
        } else if cameraReady {
            captureView
        } else {
            // Camera access is settled before AWS's detector starts, as on
            // Android: a permission prompt appearing over a running capture
            // fails the check, which hit first-time users when showStartPage
            // is false (the detector then starts as soon as this view appears).
            config.backgroundColor
                .ignoresSafeArea()
                .onAppear(perform: ensureCameraAccess)
        }
    }

    private func ensureCameraAccess() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraReady = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        cameraReady = true
                    } else {
                        onCompletion(.failure(Self.cameraDenied("the person declined the camera permission prompt")))
                    }
                }
            }
        case .denied, .restricted:
            onCompletion(.failure(Self.cameraDenied("camera access is denied or restricted in Settings")))
        @unknown default:
            cameraReady = true
        }
    }

    private static func cameraDenied(_ detail: String) -> LivenessError {
        LivenessError(
            code: LivenessError.cameraPermissionDeniedCode,
            userMessage: "Camera access is required for the liveness check. Please allow camera access in Settings and try again.",
            debugMessage: "Camera permission not granted: \(detail)"
        )
    }

    private var captureView: some View {
        VStack(spacing: 0) {
            if let title = config.customTitle {
                Text(title)
                    .font(config.font(.title2, .bold))
                    .foregroundColor(config.getPrimaryColor())
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(backgroundColor)
            }

            FaceLivenessDetectorView(
                sessionID: sessionID,
                region: region,
                // AWS's start view is never used: the SDK has its own start
                // page, or the host app provides one (showStartPage = false).
                disableStartView: true,
                isPresented: $isPresented
            ) { result in
                switch result {
                case .success:
                    // The result payload is attached by LivenessSDK when
                    // gateway credentials were provided.
                    onCompletion(.success(nil))
                case .failure(let err):
                    onCompletion(.failure(Self.mapDetectorError(err)))
                }
            }
            .hidesCancelButton(config.hideCancelButton)
            .faceLivenessDetectorTheme(config.makeDetectorTheme())
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if !config.hideBranding {
                HStack {
                    Text(sidLocalized("sid_liveness_powered_by", "Powered by "))
                        .font(config.font(.headline, .medium))
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
        config.backgroundColor
    }

    /// Maps the AWS detector failure to a [LivenessError] with a friendly
    /// user message per failure kind and the full technical detail preserved
    /// for logging (aligned with the Android SDK's messages).
    private static func mapDetectorError(_ error: Error) -> LivenessError {
        guard let detectorError = error as? FaceLivenessDetectionError else {
            return LivenessError(
                code: LivenessError.detectorFailedCode,
                userMessage: "Something went wrong during the liveness check. Please check your connection and try again.",
                debugMessage: "\(type(of: error)): \(error.localizedDescription)"
            )
        }

        if detectorError == .userCancelled {
            return LivenessError.cancelled()
        }

        let userMessage: String
        switch detectorError {
        case .sessionNotFound:
            userMessage = "This verification session is invalid or was already used. Please start a new check."
        case .sessionTimedOut:
            userMessage = "The verification session timed out. Please start a new check."
        case .faceInOvalMatchExceededTimeLimitError:
            userMessage = "We couldn't capture your face in time. Find a well-lit spot and try again."
        case .cameraPermissionDenied:
            userMessage = "Camera access is required for the liveness check. Please allow camera access in Settings and try again."
        case .cameraNotAvailable:
            userMessage = "The camera could not be started. Close other apps using the camera and try again."
        case .accessDenied:
            userMessage = "The verification service rejected the request. Please try again later."
        default:
            userMessage = "Something went wrong during the liveness check. Please check your connection and try again."
        }

        var debugMessage = detectorError.message
        if !detectorError.recoverySuggestion.isEmpty {
            debugMessage += " — \(detectorError.recoverySuggestion)"
        }

        return LivenessError(
            code: LivenessError.detectorFailedCode,
            userMessage: userMessage,
            debugMessage: debugMessage
        )
    }
}
