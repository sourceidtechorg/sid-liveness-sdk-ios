//
//  LivenessStartView.swift
//  LivenessCheck
//

import SwiftUI

private let guidelines = [
    "Use a well-lit space with even lighting, avoid very dark or overly bright areas.",
    "Keep your head centered and follow prompts.",
    "Remove any head coverings which may be obstructing your face.",
    "After 5 fails, apply a 30-60 minute timeout.",
    "When you're ready, tap Start."
]

/// Instruction page shown before the capture flow starts, mirroring the
/// SourceID web liveness start page.
struct LivenessStartView: View {
    let config: LivenessUIConfig
    let onStart: () -> Void

    private var isDark: Bool { config.theme.lowercased() == "dark" }
    private var textColor: Color { isDark ? .white : Color(red: 0.07, green: 0.07, blue: 0.07) }
    private var cardBackground: Color {
        isDark ? Color.white.opacity(0.08) : Color(red: 0.96, green: 0.95, blue: 0.98)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    Text(config.customTitle ?? "Liveness Check")
                        .font(.largeTitle.bold())
                        .foregroundColor(textColor)
                        .multilineTextAlignment(.center)

                    Text("We need to verify you are a real person for security purposes.")
                        .font(.body)
                        .foregroundColor(textColor)
                        .multilineTextAlignment(.center)
                        .padding(.top, 48)

                    FaceScanIcon(tint: config.getPrimaryColor())
                        .frame(width: 120, height: 120)
                        .padding(.top, 32)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your face needs to be verified against your information. Please follow the guidelines below to ensure proper capture:")
                            .font(.subheadline)
                            .foregroundColor(textColor)
                        ForEach(guidelines, id: \.self) { line in
                            Text("- \(line)")
                                .font(.footnote)
                                .foregroundColor(textColor)
                                .padding(.vertical, 2)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12).fill(cardBackground))
                    .padding(.top, 32)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }

            Button(action: onStart) {
                Text("Start Liveness Check")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(RoundedRectangle(cornerRadius: 8).fill(config.getPrimaryColor()))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background((isDark ? Color.black : Color.white).ignoresSafeArea())
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
