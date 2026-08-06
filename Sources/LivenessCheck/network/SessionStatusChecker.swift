//
//  SessionStatusChecker.swift
//  LivenessCheck
//

import Foundation

/// The gateway's view of a liveness session. `confidence` and
/// `referenceImageUrl` are present once the session has been run and scored
/// (status "SUCCEEDED").
public struct GatewaySessionResult: Equatable {
    public let status: String
    public let confidence: Double?
    public let referenceImageUrl: String?
}

/// Outcome of a session status query, kept distinct so callers can phrase
/// user-facing messages accurately (gateway said no vs. couldn't reach it).
enum StatusCheckOutcome {
    /// The gateway answered with the session's state.
    case status(GatewaySessionResult)
    /// The gateway answered but rejected the request (non-2xx). This is also
    /// what happens for sessions that were already run.
    case gatewayRejected(httpCode: Int, gatewayMessage: String?)
    /// The gateway could not be reached or answered garbage.
    case unreachable(detail: String)
}

extension LivenessError {
    /// Maps a status-check outcome to the error to surface, or nil when the
    /// session is usable (status CREATED).
    static func from(outcome: StatusCheckOutcome) -> LivenessError? {
        switch outcome {
        case .status(let result):
            if result.status.caseInsensitiveCompare(LivenessSDK.statusCreated) == .orderedSame {
                return nil
            }
            return LivenessError(
                code: LivenessError.sessionNotUsableCode,
                userMessage: "This verification session has already been used or has expired. Please start a new check.",
                debugMessage: "Gateway reported session status \"\(result.status)\"; launch requires \"\(LivenessSDK.statusCreated)\""
            )
        case .gatewayRejected(let httpCode, let gatewayMessage):
            // 401/403 is an endpoint/config problem, not a spent session;
            // other rejections (the gateway also 400s for already-run
            // sessions) mean "don't open the camera".
            if httpCode == 401 || httpCode == 403 {
                return LivenessError(
                    code: LivenessError.statusCheckFailedCode,
                    userMessage: "We couldn't verify your session. Please try again later.",
                    debugMessage: "Gateway rejected the status check with HTTP \(httpCode) (auth) — \(gatewayMessage ?? "no message")"
                )
            }
            return LivenessError(
                code: LivenessError.sessionNotUsableCode,
                userMessage: "This verification session has already been used or has expired. Please start a new check.",
                debugMessage: "Gateway rejected the status check: HTTP \(httpCode) — \(gatewayMessage ?? "no message")"
            )
        case .unreachable(let detail):
            return LivenessError(
                code: LivenessError.statusCheckFailedCode,
                userMessage: "We couldn't verify your session. Please check your internet connection and try again.",
                debugMessage: "Status check failed before reaching a verdict: \(detail)"
            )
        }
    }
}

/// Queries the gateway's `POST /liveness/liveness-result` endpoint for the
/// status of a session. The endpoint expects the session id in the
/// `reference` field and reports `data.status` (e.g. "CREATED") for a
/// session that has not been run yet.
enum SessionStatusChecker {

    static func fetchStatus(environment: LivenessEnvironment, sessionId: String) async -> StatusCheckOutcome {
        // The gateway route is the liveness base itself (POST /v1/api/liveness).
        guard let url = URL(string: environment.baseUrl) else {
            return .unreachable(detail: "Invalid gateway base URL: \(environment.baseUrl)")
        }

        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: ["reference": sessionId])
            let (data, response) = try await URLSession.shared.data(for: request)
            let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]

            let httpCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard (200..<300).contains(httpCode) else {
                let gatewayMessage = (json?["message"] as? String).flatMap { $0.isEmpty ? nil : $0 }
                return .gatewayRejected(httpCode: httpCode, gatewayMessage: gatewayMessage)
            }

            let payload = json?["data"] as? [String: Any]
            guard let status = payload?["status"] as? String, !status.isEmpty else {
                let body = String(data: data.prefix(200), encoding: .utf8) ?? ""
                return .unreachable(detail: "Gateway response has no session status (body: \(body))")
            }
            return .status(GatewaySessionResult(
                status: status,
                confidence: (payload?["confidence"] as? NSNumber)?.doubleValue,
                referenceImageUrl: (payload?["referenceImageUrl"] as? String).flatMap { $0.isEmpty ? nil : $0 }
            ))
        } catch {
            return .unreachable(detail: "\(type(of: error)): \(error.localizedDescription)")
        }
    }
}
