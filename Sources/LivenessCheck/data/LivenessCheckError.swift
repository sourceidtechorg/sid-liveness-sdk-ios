//
//  LivenessCheckError.swift
//  LivenessCheck
//

import Foundation

/// Errors reported through `LivenessResult.failure`, with messages aligned
/// with the Android SDK's error contract.
public enum LivenessCheckError: LocalizedError, Equatable {
    /// `start` was called with blank arguments.
    case invalidArguments(String)
    /// The pre-flight status check blocked the launch (used/expired session,
    /// or the gateway could not confirm the session is usable).
    case sessionNotUsable(String)
    /// The user backed out of the flow before completing it.
    case cancelled
    /// The AWS Face Liveness detector failed (network, expired session, ...).
    case detectorFailure(String)

    public var errorDescription: String? {
        switch self {
        case .invalidArguments(let message): return message
        case .sessionNotUsable(let message): return message
        case .cancelled: return "Liveness check cancelled"
        case .detectorFailure(let message): return message
        }
    }
}
