//
//  LivenessApiConfig.swift
//  LivenessCheck
//

import Foundation

/// Connection details for the SourceID gateway, used to verify a liveness
/// session's status before the capture flow is launched.
///
/// - `baseUrl`: gateway API base, e.g. `https://api-rd.tailfaed50.ts.net/v1/api`
/// - `apiKey`: value for the `x-api-key` header.
/// - `bearerToken`: value for the `Authorization: Bearer` header. Tokens
///   expire — supply a fresh one per launch.
public struct LivenessApiConfig {
    public let baseUrl: String
    public let apiKey: String
    public let bearerToken: String

    public init(baseUrl: String, apiKey: String, bearerToken: String) {
        self.baseUrl = baseUrl
        self.apiKey = apiKey
        self.bearerToken = bearerToken
    }
}
