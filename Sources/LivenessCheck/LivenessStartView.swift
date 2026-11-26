//
//  LivenessStartView.swift
//  LivenessCheck
//

import SwiftUI

/// Start-page guidelines. Keys are shared with Android (CONTRACT.md); a host
/// `Localizable.strings` with the same key replaces or translates the text.
private var guidelines: [String] {
    [
        sidLocalized("sid_liveness_start_guideline_light", "Use a well-lit space with even lighting, avoid very dark or overly bright areas."),
        sidLocalized("sid_liveness_start_guideline_center", "Keep your head centered and follow prompts."),
        sidLocalized("sid_liveness_start_guideline_coverings", "Remove any head coverings which may be obstructing your face."),
        sidLocalized("sid_liveness_start_guideline_photosensitivity", "The check flashes a sequence of colours on screen. Take care if you are sensitive to flashing light."),
        sidLocalized("sid_liveness_start_guideline_retries", "After 5 fails, apply a 30-60 minute timeout."),
        sidLocalized("sid_liveness_start_guideline_ready", "When you're ready, tap Start."),
    ]
}

/// Instruction page shown before the capture flow starts, mirroring the
/// SourceID web liveness start page. Hidden with `showStartPage = false`.
struct LivenessStartView: View {
    let config: LivenessUIConfig
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    Text(config.customTitle ?? sidLocalized("sid_liveness_start_title", "Liveness Check"))
                        .font(config.font(.largeTitle, .bold))
                        .foregroundColor(config.textColor)
                        .multilineTextAlignment(.center)

                    Text(sidLocalized("sid_liveness_start_intro", "We need to verify you are a real person for security purposes."))
                        .font(config.font(.body, .regular))
                        .foregroundColor(config.textColor)
                        .multilineTextAlignment(.center)
                        .padding(.top, 48)

                    FaceScanIcon(tint: config.getPrimaryColor())
                        .frame(width: 120, height: 120)
                        .padding(.top, 32)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(sidLocalized("sid_liveness_start_guidelines_intro", "Your face needs to be verified against your information. Please follow the guidelines below to ensure proper capture:"))
                            .font(config.font(.subheadline, .regular))
                            .foregroundColor(config.textColor)
                        ForEach(guidelines, id: \.self) { line in
                            // A separate bullet keeps it at the leading edge in right-to-left languages.
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text(verbatim: "•")
                                Text(line)
                            }
                            .font(config.font(.footnote, .regular))
                            .foregroundColor(config.textColor)
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12).fill(config.surfaceColor))
                    .padding(.top, 32)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }

            Button(action: onStart) {
                Text(sidLocalized("sid_liveness_start_button", "Start Liveness Check"))
                    .font(config.font(.body, .medium))
                    .foregroundColor(config.onPrimaryColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(RoundedRectangle(cornerRadius: 8).fill(config.getPrimaryColor()))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background(config.backgroundColor.ignoresSafeArea())
    }
}

/// Person silhouette inside camera-style corner brackets.
private struct FaceScanIcon: View {
    let tint: Color

    var body: some View {
        ZStack {
            CornerBrackets()
                .stroke(tint, lineWidth: 5)
            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundColor(tint)
        }
    }
}

private struct CornerBrackets: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let corner = rect.width * 0.22
        // top-left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + corner))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + corner, y: rect.minY))
        // top-right
        path.move(to: CGPoint(x: rect.maxX - corner, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + corner))
        // bottom-left
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY - corner))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + corner, y: rect.maxY))
        // bottom-right
        path.move(to: CGPoint(x: rect.maxX - corner, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - corner))
        return path
    }
}
