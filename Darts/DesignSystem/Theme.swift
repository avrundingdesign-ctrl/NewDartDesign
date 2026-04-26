import SwiftUI

// MARK: - Farben (gemappt aus dem darts-app.html Mockup)
extension Color {
    static let dBg0          = Color(red: 0.051, green: 0.051, blue: 0.102) // #0d0d1a
    static let dBg1          = Color(red: 0.071, green: 0.071, blue: 0.122) // #12121f
    static let dBg2          = Color(red: 0.102, green: 0.102, blue: 0.180) // #1a1a2e
    static let dBg3          = Color(red: 0.118, green: 0.118, blue: 0.204) // #1e1e34
    static let dBorder       = Color.white.opacity(0.08)
    static let dPurple       = Color(red: 0.486, green: 0.227, blue: 0.929) // #7c3aed
    static let dPurpleLight  = Color(red: 0.655, green: 0.545, blue: 0.980) // #a78bfa
    static let dPurpleDim    = Color(red: 0.176, green: 0.122, blue: 0.369) // #2d1f5e
    static let dGreen        = Color(red: 0.204, green: 0.827, blue: 0.600) // #34d399
    static let dGreenDim     = Color(red: 0.051, green: 0.180, blue: 0.102) // #0d2e1a
    static let dRed          = Color(red: 0.973, green: 0.443, blue: 0.443) // #f87171
    static let dRedDim       = Color(red: 0.180, green: 0.102, blue: 0.102) // #2e1a1a
    static let dAmber        = Color(red: 0.984, green: 0.749, blue: 0.141) // #fbbf24
    static let dText         = Color(red: 0.886, green: 0.886, blue: 0.910) // #e2e2e8
    static let dTextMuted    = Color(red: 0.400, green: 0.400, blue: 0.400) // #666
    static let dTextDim      = Color(red: 0.267, green: 0.267, blue: 0.267) // #444
}

// MARK: - Typografie
enum DartsFont {
    static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - View-Modifier (Mockup-Schliff)
extension View {
    /// Card-Hintergrund wie `.score-card` / `.mode-card` im Mockup.
    func dartsCard(active: Bool = false, padding: CGFloat = 12) -> some View {
        self
            .padding(padding)
            .background(Color.dBg2)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(active ? Color.dPurple : Color.dBorder, lineWidth: active ? 1 : 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    /// Großer Primary-Button (`.btn-primary`).
    func dartsPrimaryButton(enabled: Bool = true) -> some View {
        self
            .font(DartsFont.sans(14, weight: .medium))
            .foregroundStyle(enabled ? Color.white : Color.dTextDim)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(enabled ? Color.dPurple : Color.dBg3)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    /// Outline-Button (`.btn-outline`).
    func dartsOutlineButton() -> some View {
        self
            .font(DartsFont.sans(14, weight: .medium))
            .foregroundStyle(Color.dPurpleLight)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.dPurpleDim)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.dPurple, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Section-Label (`.section-label` aus Mockup)
struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(DartsFont.sans(10, weight: .regular))
            .tracking(0.8)
            .foregroundStyle(Color.dTextMuted)
    }
}
