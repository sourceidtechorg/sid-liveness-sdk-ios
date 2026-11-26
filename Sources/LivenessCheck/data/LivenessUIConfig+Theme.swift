//
//  LivenessUIConfig+Theme.swift
//  LivenessCheck
//
//  Resolves a LivenessUIConfig into concrete colours, fonts and the AWS
//  detector theme. Defaults match the SDK's pre-1.9 look exactly.
//

import SwiftUI
import FaceLiveness

extension LivenessUIConfig {
    var isDark: Bool { theme.lowercased() == "dark" }

    /// Screen background around the camera, start page, title bar and footer.
    var backgroundColor: Color {
        Color.fromHex(colors.background) ?? (isDark ? .black : .white)
    }

    /// Text on `backgroundColor`.
    var textColor: Color {
        Color.fromHex(colors.onBackground) ?? (isDark ? .white : Color(red: 0.07, green: 0.07, blue: 0.07))
    }

    /// Text and icons on the primary colour. Without a configured primary the
    /// dark theme's primary is white, so its default text must be dark.
    var onPrimaryColor: Color {
        if let c = Color.fromHex(colors.onPrimary) { return c }
        let hasPrimary = Color.fromHex(colors.primary ?? primaryColorHex) != nil
        return isDark && !hasPrimary ? .black : .white
    }

    /// Start-page guideline card.
    var surfaceColor: Color {
        Color.fromHex(colors.surface) ?? (isDark ? Color.white.opacity(0.08) : Color(red: 0.96, green: 0.95, blue: 0.98))
    }

    /// A font for one of the SDK's own text styles: the host's custom font when
    /// configured, the system font otherwise.
    func font(_ style: Font.TextStyle, _ role: LivenessFonts.Role) -> Font {
        if let name = fonts.name(for: role) {
            return .custom(name, size: style.defaultPointSize, relativeTo: style)
        }
        switch role {
        case .regular: return .system(style)
        case .medium: return Font.system(style).weight(.semibold)
        case .bold: return Font.system(style).weight(.bold)
        }
    }

    /// The AWS detector theme: starts from AWS's light or dark palette (by
    /// `theme`) and overrides every colour and font the host configured.
    @MainActor
    func makeDetectorTheme() -> FaceLivenessDetectorTheme {
        let detectorTheme = FaceLivenessDetectorTheme(colorScheme: isDark ? .dark : .light)
        var palette = detectorTheme.colors
        if let c = Color.fromHex(colors.primary ?? primaryColorHex) { palette.primary = c }
        if let c = Color.fromHex(colors.onPrimary) { palette.onPrimary = c }
        if let c = Color.fromHex(colors.background) { palette.background = c }
        if let c = Color.fromHex(colors.onBackground) { palette.onBackground = c }
        if let c = Color.fromHex(colors.surface) { palette.surface = c }
        if let c = Color.fromHex(colors.error) { palette.error = c }
        if let c = Color.fromHex(colors.onError) { palette.onError = c }
        if let c = Color.fromHex(colors.errorContainer) { palette.errorContainer = c }
        if let c = Color.fromHex(colors.onErrorContainer) { palette.onErrorContainer = c }
        detectorTheme.colors = palette

        if !fonts.isEmpty {
            var detectorFonts = detectorTheme.fonts
            detectorFonts.largeTitle = font(.largeTitle, .bold)
            detectorFonts.title = font(.title, .bold)
            detectorFonts.title2 = font(.title2, .bold)
            detectorFonts.title3 = font(.title3, .medium)
            detectorFonts.headline = font(.headline, .medium)
            detectorFonts.subheadline = font(.subheadline, .regular)
            detectorFonts.body = font(.body, .regular)
            detectorFonts.callout = font(.callout, .regular)
            detectorFonts.caption = font(.caption, .regular)
            detectorFonts.caption2 = font(.caption2, .regular)
            detectorFonts.footnote = font(.footnote, .regular)
            detectorTheme.fonts = detectorFonts
        }
        return detectorTheme
    }
}

extension LivenessFonts {
    enum Role { case regular, medium, bold }

    /// The configured font for a role, falling back bold → medium → regular.
    func name(for role: Role) -> String? {
        switch role {
        case .regular: return regular
        case .medium: return medium ?? regular
        case .bold: return bold ?? medium ?? regular
        }
    }
}

extension Font.TextStyle {
    /// Point size of each text style at the default Dynamic Type setting, so
    /// custom fonts start at the system size and still scale with the user's
    /// text-size preference.
    var defaultPointSize: CGFloat {
        switch self {
        case .largeTitle: return 34
        case .title: return 28
        case .title2: return 22
        case .title3: return 20
        case .headline: return 17
        case .subheadline: return 15
        case .body: return 17
        case .callout: return 16
        case .footnote: return 13
        case .caption: return 12
        case .caption2: return 11
        @unknown default: return 17
        }
    }
}

/// SourceID's own text, overridable by the host app: a `Localizable.strings`
/// in the app bundle (including translations such as `ar.lproj`) with the same
/// key wins; otherwise the English default is used.
func sidLocalized(_ key: String, _ defaultValue: String) -> String {
    NSLocalizedString(key, tableName: nil, bundle: .main, value: defaultValue, comment: "")
}
