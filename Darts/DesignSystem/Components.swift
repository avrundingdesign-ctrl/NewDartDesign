import SwiftUI

// MARK: - Step-Progress (3 Balken)
struct StepProgress: View {
    /// 0-indexed aktiver Schritt. Frühere Steps sind "done".
    let active: Int
    let total: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<total, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor(for: i))
                    .frame(height: 2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    private func barColor(for i: Int) -> Color {
        if i < active { return .dPurple }
        if i == active { return .dPurpleLight }
        return .dBg3
    }
}

// MARK: - Player-Chip
struct PlayerChip: View {
    let name: String
    let index: Int
    let onRemove: () -> Void

    private static let bgColors: [Color] = [.dPurpleDim, .dGreenDim, Color(red: 0.18, green: 0.165, blue: 0.051), .dRedDim]
    private static let fgColors: [Color] = [.dPurpleLight, Color(red: 0.43, green: 0.91, blue: 0.72), .dAmber, Color(red: 0.96, green: 0.45, blue: 0.71)]

    var body: some View {
        HStack(spacing: 6) {
            Text(name.prefix(2).uppercased())
                .font(DartsFont.sans(9, weight: .semibold))
                .foregroundStyle(Self.fgColors[index % 4])
                .frame(width: 24, height: 24)
                .background(Self.bgColors[index % 4])
                .clipShape(Circle())
            Text(name)
                .font(DartsFont.sans(12))
                .foregroundStyle(Color(white: 0.8))
            Button(action: onRemove) {
                Text("×")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.dRed)
                    .frame(width: 14, height: 14)
                    .background(Color.dRedDim)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 5)
        .padding(.trailing, 10)
        .padding(.vertical, 5)
        .background(Color.dBg3)
        .overlay(
            RoundedRectangle(cornerRadius: 20).stroke(Color.dBorder, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Mode-Card (`.mode-card`)
struct ModeCard: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(DartsFont.sans(15, weight: .semibold))
                    .foregroundStyle(Color.dText)
                Text(subtitle)
                    .font(DartsFont.sans(11))
                    .foregroundStyle(Color.dTextMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(isSelected ? Color.dPurpleDim.opacity(0.5) : Color.dBg2)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.dPurple : Color.dBorder, lineWidth: isSelected ? 1 : 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Legs-Button (`.legs-btn`)
struct LegsButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(DartsFont.sans(12))
                .foregroundStyle(isSelected ? Color.dPurpleLight : Color.dTextMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(isSelected ? Color.dPurpleDim : Color.dBg2)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isSelected ? Color.dPurple : Color.dBorder, lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Throw-Pill (`.throw-pill`)
struct ThrowPill: View {
    enum Style { case neutral, hit, bust }
    let text: String
    let style: Style

    var body: some View {
        Text(text)
            .font(DartsFont.mono(11))
            .foregroundStyle(fg)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private var fg: Color {
        switch style {
        case .neutral: return Color(white: 0.67)
        case .hit:     return .dPurpleLight
        case .bust:    return .dRed
        }
    }
    private var bg: Color {
        switch style {
        case .neutral: return .dBg3
        case .hit:     return .dPurpleDim
        case .bust:    return .dRedDim
        }
    }
}

// MARK: - Check-Item (Kalibrierungs-Liste)
struct CheckItem: View {
    enum CheckState { case pending, ok, error }
    let name: String
    let value: String
    let state: CheckState

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)
                .opacity(state == .pending ? blinkOpacity : 1)
            Text(name)
                .font(DartsFont.sans(12))
                .foregroundStyle(Color(white: 0.53))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(value)
                .font(DartsFont.mono(11))
                .foregroundStyle(Color.dTextMuted)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.dBg2)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @State private var blinkOpacity: Double = 1
    private var dotColor: Color {
        switch state {
        case .pending: return .dPurpleLight
        case .ok: return .dGreen
        case .error: return .dRed
        }
    }
}

// MARK: - Shimmer / Pulse für laufende Elemente
struct PulseDot: View {
    @State private var on = false
    var body: some View {
        Circle()
            .fill(Color.dPurpleLight)
            .frame(width: 6, height: 6)
            .opacity(on ? 1 : 0.25)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: on)
            .onAppear { on = true }
    }
}

// MARK: - Logo-Icon (im Setup verwendet)
struct LogoIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.dPurple, lineWidth: 2)
                .frame(width: 60, height: 60)
            Circle()
                .stroke(Color.dPurple, lineWidth: 1)
                .frame(width: 28, height: 28)
            Circle()
                .fill(Color.dPurple)
                .frame(width: 6, height: 6)
        }
    }
}

// MARK: - Bust-Toast (kurze Einblendung)
struct BustToast: View {
    let text: String
    var body: some View {
        Text(text)
            .font(DartsFont.sans(16, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 10)
            .background(Color.dRed.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
