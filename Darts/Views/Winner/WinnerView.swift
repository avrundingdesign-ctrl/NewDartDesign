import SwiftUI

struct WinnerView: View {
    @EnvironmentObject var engine: GameEngine
    let winnerName: String

    private var winner: Player? {
        engine.players.first(where: { $0.name == winnerName })
    }

    var body: some View {
        ZStack {
            Color.dBg1.ignoresSafeArea()
            ConfettiLayer()

            VStack(spacing: 14) {
                Spacer()
                Image(systemName: "rosette")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(Color.dPurpleLight)
                Text("Sieger")
                    .font(DartsFont.sans(11))
                    .foregroundStyle(Color.dPurpleLight)
                    .tracking(1)
                    .textCase(.uppercase)
                Text(winnerName)
                    .font(DartsFont.sans(32, weight: .semibold))
                    .foregroundStyle(Color.dText)
                Text(subline)
                    .font(DartsFont.sans(12))
                    .foregroundStyle(Color.dTextMuted)
                    .padding(.bottom, 8)

                if let p = winner {
                    HStack(spacing: 8) {
                        statBlock(value: "\(p.average)", label: "⌀ Aufnahme")
                        statBlock(value: "\(p.bestTurn)", label: "Beste")
                        statBlock(value: "\(p.turnTotals.count)", label: "Aufnahmen")
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 4)
                }

                Spacer()

                Button {
                    engine.backToSetup()
                } label: {
                    Text("Neues Spiel")
                        .dartsPrimaryButton()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
            }
        }
    }

    private var subline: String {
        let mode = engine.setup.mode.rawValue
        let bo = engine.setup.legsToPlay
        return "\(mode) · Best of \(bo) · Runde \(engine.turnNumber)"
    }

    private func statBlock(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(DartsFont.mono(18, weight: .semibold))
                .foregroundStyle(Color.dPurpleLight)
            Text(label)
                .font(DartsFont.sans(10))
                .foregroundStyle(Color.dTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.dBg2)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Konfetti
struct ConfettiPiece: Identifiable {
    let id = UUID()
    let xRel: CGFloat
    let color: Color
    let duration: Double
    let delay: Double
    let size: CGFloat
}

struct ConfettiLayer: View {
    @State private var pieces: [ConfettiPiece] = []

    private let palette: [Color] = [
        .dPurple, .dPurpleLight, .dGreen, .dAmber, .dRed,
        Color(red: 0.376, green: 0.647, blue: 0.980)
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(pieces) { p in
                    ConfettiDot(piece: p, totalHeight: proxy.size.height, totalWidth: proxy.size.width)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            pieces = (0..<48).map { _ in
                ConfettiPiece(
                    xRel: .random(in: 0...1),
                    color: palette.randomElement()!,
                    duration: .random(in: 2.0...4.0),
                    delay: .random(in: 0...2.0),
                    size: .random(in: 4...7)
                )
            }
        }
    }
}

private struct ConfettiDot: View {
    let piece: ConfettiPiece
    let totalHeight: CGFloat
    let totalWidth: CGFloat
    @State private var fall: Bool = false

    var body: some View {
        Circle()
            .fill(piece.color)
            .frame(width: piece.size, height: piece.size)
            .position(x: piece.xRel * totalWidth, y: fall ? totalHeight + 20 : -20)
            .opacity(fall ? 0 : 1)
            .onAppear {
                withAnimation(.linear(duration: piece.duration).delay(piece.delay).repeatForever(autoreverses: false)) {
                    fall = true
                }
            }
    }
}
