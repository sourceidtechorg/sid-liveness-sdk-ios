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
    case uat
    case development

    var baseUrl: String {
        switch self {
        case .production: return "https://api.usesourceid.com/v1/api"
        case .sandbox: return "https://api.sbx.usesourceid.com/v1/api"
        case .uat: return "https://api.uat.usesourceid.com/v1/api"
        case .development: return "https://api-rd.tailfaed50.ts.net/v1/api"
        }
    }

    /// Case-insensitive lookup, e.g. "production", "SANDBOX".
    public static func fromName(_ name: String?) -> LivenessEnvironment? {
        guard let name else { return nil }
        return LivenessEnvironment(rawValue: name.lowercased())
    }
}
