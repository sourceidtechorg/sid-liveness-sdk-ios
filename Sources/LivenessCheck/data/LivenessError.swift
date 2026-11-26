//
//  LivenessError.swift
//  LivenessCheck
//

import Foundation

/// Structured error delivered through `LivenessResult.failure`, aligned with
/// the Android SDK's error contract.
///
/// - `userMessage` is friendly, actionable text safe to show end users
///   (alert/toast/banner). It is also what `localizedDescription` returns.
/// - `debugMessage` carries the full technical detail for logging and bug
///   reports; the SDK also logs it under the `tech.sourceid.LivenessCheck`
///   subsystem (filter in Xcode's console or Console.app).
/// - `code` is a stable machine-readable identifier for programmatic handling.
public struct LivenessError: Error, Equatable, LocalizedError, CustomStringConvertible {
    public let code: String
    public let userMessage: String
    public let debugMessage: String

    public init(code: String, userMessage: String, debugMessage: String) {
        self.code = code
        self.userMessage = userMessage
        self.debugMessage = debugMessage
    }

    /// True when the user cancelled the flow rather than failing it.
    public var isCancelled: Bool { code == Self.cancelledCode }

    public var errorDescription: String? { userMessage }
    public var description: String { "[\(code)] \(debugMessage)" }

    public static let cancelledCode = "CANCELLED"
    public static let cameraPermissionDeniedCode = "CAMERA_PERMISSION_DENIED"
    public static let invalidArgumentsCode = "INVALID_ARGUMENTS"
    public static let configFailedCode = "CONFIG_FAILED"
    public static let sessionNotUsableCode = "SESSION_NOT_USABLE"
    public static let statusCheckFailedCode = "STATUS_CHECK_FAILED"
    public static let detectorFailedCode = "DETECTOR_FAILED"

    public static func cancelled() -> LivenessError {
        LivenessError(
            code: cancelledCode,
            userMessage: "Liveness check cancelled",
            debugMessage: "User backed out of the flow before completing it"
        )
    }
}
