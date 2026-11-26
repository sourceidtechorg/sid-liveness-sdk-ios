//
//  LivenessUIConfig.swift
//  LivenessCheck
//
//  Created by Richard Uzor on 03/10/2025.
//

import SwiftUI

/// Look and behaviour of the liveness flow. Field names and defaults are
/// shared with the Android SDK; see CONTRACT.md.
public struct LivenessUIConfig {
    /// Hides the "Powered by SourceID" footer.
    public var hideBranding: Bool
    /// Title above the camera and on the start page. Hidden above the camera when nil.
    public var customTitle: String?
    /// `"light"` or `"dark"`: the base palette every colour falls back to.
    public var theme: String
    /// Shorthand for `colors.primary`; `colors.primary` wins when both are set.
    public var primaryColorHex: String?
    /// Shows the SourceID instruction page before the camera. Set `false`
    /// when the host app provides its own intro.
    public var showStartPage: Bool
    /// Hides AWS's close button during capture. Only hide it when the host
    /// gives the person another way out.
    public var hideCancelButton: Bool
    /// Full palette; each colour falls back to the `theme` default.
    public var colors: LivenessColors
    /// Custom fonts; each falls back to the system font.
    public var fonts: LivenessFonts

    public init(
        hideBranding: Bool = false,
        customTitle: String? = nil,
        theme: String = "light",
        primaryColorHex: String? = nil,
        showStartPage: Bool = true,
        hideCancelButton: Bool = false,
        colors: LivenessColors = .init(),
        fonts: LivenessFonts = .init()
    ) {
        self.hideBranding = hideBranding
        self.customTitle = customTitle
        self.theme = theme
        self.primaryColorHex = primaryColorHex
        self.showStartPage = showStartPage
        self.hideCancelButton = hideCancelButton
        self.colors = colors
        self.fonts = fonts
    }

    public func getPrimaryColor() -> Color {
        Color.fromHex(colors.primary ?? primaryColorHex) ?? (isDark ? .white : .black)
    }
}

/// Optional `"#RRGGBB"` colours. Names follow the Material / AWS Amplify roles,
/// so they map one-to-one onto the AWS detector theme on both platforms.
public struct LivenessColors {
    /// Buttons, accents, start-page icon, title.
    public var primary: String?
    /// Text and icons on `primary`.
    public var onPrimary: String?
    /// Screen background around the camera, start page, title bar, footer.
    public var background: String?
    /// Text on `background`, including capture guidance.
    public var onBackground: String?
    /// Start-page guideline card; AWS surfaces.
    public var surface: String?
    public var error: String?
    public var onError: String?
    public var errorContainer: String?
    public var onErrorContainer: String?

    public init(
        primary: String? = nil,
        onPrimary: String? = nil,
        background: String? = nil,
        onBackground: String? = nil,
        surface: String? = nil,
        error: String? = nil,
        onError: String? = nil,
        errorContainer: String? = nil,
        onErrorContainer: String? = nil
    ) {
        self.primary = primary
        self.onPrimary = onPrimary
        self.background = background
        self.onBackground = onBackground
        self.surface = surface
        self.error = error
        self.onError = onError
        self.errorContainer = errorContainer
        self.onErrorContainer = onErrorContainer
    }
}

/// PostScript names of fonts registered by the host app (for example listed
/// under `UIAppFonts`). Unknown names fall back to the system font.
public struct LivenessFonts {
    /// Body, captions, guidance.
    public var regular: String?
    /// Headlines, labels, buttons. Falls back to `regular`.
    public var medium: String?
    /// Titles. Falls back to `medium`, then `regular`.
    public var bold: String?

    public init(regular: String? = nil, medium: String? = nil, bold: String? = nil) {
        self.regular = regular
        self.medium = medium
        self.bold = bold
    }

    public var isEmpty: Bool { regular == nil && medium == nil && bold == nil }
}
