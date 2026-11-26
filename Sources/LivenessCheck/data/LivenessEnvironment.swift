//
//  LivenessEnvironment.swift
//  LivenessCheck
//

import Foundation

/// SourceID gateway environment. Consumers pass only the environment — the
/// SDK derives the gateway base URL internally.
public enum LivenessEnvironment: String, CaseIterable {
    case production
    case sandbox
    case development

    var baseUrl: String {
        switch self {
        case .production: return "https://core-api.sourceid.tech/v1/api/liveness"
        case .sandbox: return "https://core-api.sbx.sourceid.tech/v1/api/liveness"
        case .development: return "https://core-api-rd.tailfaed50.ts.net/v1/api/liveness"
        }
    }

    /// Case-insensitive lookup, e.g. "production", "SANDBOX".
    public static func fromName(_ name: String?) -> LivenessEnvironment? {
        guard let name else { return nil }
        return LivenessEnvironment(rawValue: name.lowercased())
    }
}
