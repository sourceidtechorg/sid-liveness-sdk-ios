//
//  SessionStatusChecker.swift
//  LivenessCheck
//

import Foundation

/// Queries the gateway's `POST /liveness/liveness-result` endpoint for the
/// status of a session. The endpoint expects the session id in the
/// `reference` field and reports `data.status` (e.g. "CREATED") for a
/// session that has not been run yet.
enum SessionStatusChecker {

    /// Returns the session status string, or throws with a readable message.
    static func fetchStatus(apiConfig: LivenessApiConfig, sessionId: String) async throws -> String {
        let base = apiConfig.baseUrl.hasSuffix("/")
            ? String(apiConfig.baseUrl.dropLast())
            : apiConfig.baseUrl
        guard let url = URL(string: base + "/liveness/liveness-result") else {
            throw LivenessCheckError.sessionNotUsable("Invalid gateway base URL")
        }

        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiConfig.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("Bearer \(apiConfig.bearerToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["reference": sessionId])

        let (data, response) = try await URLSession.shared.data(for: request)
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]

        let httpCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(httpCode) else {
            let gatewayMessage = (json?["message"] as? String).flatMap { $0.isEmpty ? nil : $0 }
            throw LivenessCheckError.sessionNotUsable(
                gatewayMessage ?? "Gateway returned HTTP \(httpCode)"
            )
        }

        guard let status = (json?["data"] as? [String: Any])?["status"] as? String,
              !status.isEmpty else {
            throw LivenessCheckError.sessionNotUsable("Gateway response has no session status")
        }
        return status
    }
}
