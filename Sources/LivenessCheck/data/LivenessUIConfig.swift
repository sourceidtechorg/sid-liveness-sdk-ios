//
//  LivenessUIConfig.swift
//  SDKTesters2
//
//  Created by Richard Uzor on 03/10/2025.
//

import SwiftUI

public struct LivenessUIConfig {
    public var hideBranding: Bool
    public var customTitle: String?
    public var theme: String
    public var primaryColorHex: String?

    public init(
        hideBranding: Bool = false,
        customTitle: String? = nil,
        theme: String = "light",
        primaryColorHex: String? = nil
    ) {
        self.hideBranding = hideBranding
        self.customTitle = customTitle
        self.theme = theme
        self.primaryColorHex = primaryColorHex
    }

    public func getPrimaryColor() -> Color {
        if let hex = primaryColorHex, let color = Color(hex: hex) {
            return color
        }
        return theme.lowercased() == "dark" ? .white : .black
    }
}


