//
//  SessionStatusChecker.swift
//  LivenessCheck
//

import Foundation

/// Outcome of a session status query, kept distinct so callers can phrase
/// user-facing messages accurately (gateway said no vs. couldn't reach it).
enum StatusCheckOutcome {
    /// The gateway answered with a session status (e.g. "CREATED").
    case status(String)
    /// The gateway answered but rejected the request (non-2xx). This is also
    /// what happens for sessions that were already run.
    case gatewayRejected(httpCode: Int, gatewayMessage: String?)
    /// The gateway could not be reached or answered garbage.
    case unreachable(detail: String)
}

/// Queries the gateway's `POST /liveness/liveness-result` endpoint for the
/// status of a session. The endpoint expects the session id in the
/// `reference` field and reports `data.status` (e.g. "CREATED") for a
/// session that has not been run yet.
enum SessionStatusChecker {

    static func fetchStatus(apiConfig: LivenessApiConfig, sessionId: String) async -> StatusCheckOutcome {
        let base = apiConfig.baseUrl.hasSuffix("/")
            ? String(apiConfig.baseUrl.dropLast())
            : apiConfig.baseUrl
        guard let url = URL(string: base + "/liveness/liveness-result") else {
            return .unreachable(detail: "Invalid gateway base URL: \(apiConfig.baseUrl)")
        }

        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiConfig.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("Bearer \(apiConfig.bearerToken)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: ["reference": sessionId])
            let (data, response) = try await URLSession.shared.data(for: request)
            let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]

            let httpCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard (200..<300).contains(httpCode) else {
                let gatewayMessage = (json?["message"] as? String).flatMap { $0.isEmpty ? nil : $0 }
                return .gatewayRejected(httpCode: httpCode, gatewayMessage: gatewayMessage)
            }

            guard let status = (json?["data"] as? [String: Any])?["status"] as? String,
                  !status.isEmpty else {
                let body = String(data: data.prefix(200), encoding: .utf8) ?? ""
                return .unreachable(detail: "Gateway response has no session status (body: \(body))")
            }
            return .status(status)
        } catch {
            return .unreachable(detail: "\(type(of: error)): \(error.localizedDescription)")
        }
    }
}
