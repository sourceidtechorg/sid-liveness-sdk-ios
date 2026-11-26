//
//  LivenessResult.swift
//  LivenessCheck
//
//  Created by Richard Uzor on 08/10/2025.
//


import Foundation

public enum LivenessResult {
    /// The associated `GatewaySessionResult` (status/confidence/reference
    /// image URL) is populated when `LivenessApiConfig` was provided to
    /// `start`; nil otherwise or when the post-completion fetch failed.
    case success(GatewaySessionResult?)
    case failure(LivenessError)
}
