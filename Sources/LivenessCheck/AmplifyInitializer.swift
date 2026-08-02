//
//  AmplifyInitializer.swift
//  LivenessCheck
//
//  Created by Richard Uzor on 08/10/2025.
//

import Foundation
import Amplify
import AWSCognitoAuthPlugin

enum AmplifyInitializer {

    private static var isConfigured = false

    /// Configures Amplify with the Cognito Auth plugin exactly once per process.
    /// A host app that has already configured Amplify itself is treated as success.
    /// - Throws: the underlying Amplify error when configuration genuinely fails.
    static func configureIfNeeded() throws {
        guard !isConfigured else { return }

        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            // Prefer the host app's own amplifyconfiguration.json; fall back to
            // the SourceID default bundled with the SDK.
            if Bundle.main.url(forResource: "amplifyconfiguration", withExtension: "json") != nil {
                try Amplify.configure()
            } else if let bundledConfig = Bundle.livenessCheck.url(
                forResource: "amplifyconfiguration", withExtension: "json"
            ) {
                try Amplify.configure(AmplifyConfiguration(configurationFile: bundledConfig))
            } else {
                try Amplify.configure()
            }
            isConfigured = true
        } catch let error as ConfigurationError {
            if case .amplifyAlreadyConfigured = error {
                // Configured by the host app (or an earlier launch) — fine.
                isConfigured = true
            } else {
                throw error
            }
        } catch {
            // Amplify.add(plugin:) throws a plain error once Amplify is configured.
            if error.localizedDescription.localizedCaseInsensitiveContains("already") {
                isConfigured = true
            } else {
                throw error
            }
        }
    }
}
