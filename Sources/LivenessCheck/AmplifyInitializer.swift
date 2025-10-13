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
    static func configureIfNeeded() {
      

        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.configure()
            print("✅ Amplify configured successfully (inside SDK)")
        } catch {
            print("❌ Amplify configuration failed: \(error)")
        }
    }
}
