import SwiftUI

struct ThrowDisplay: View {
    @EnvironmentObject var engine: GameEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 6) {
                Text("Letzte:")
                    .font(DartsFont.sans(10))
                    .foregroundStyle(Color.dTextDim)

                if engine.currentTurnDarts.isEmpty {
                    ThrowPill(text: "—", style: .neutral)
                } else {
                    ForEach(Array(engine.currentTurnDarts.enumerated()), id: \.offset) { _, dart in
                        ThrowPill(text: pillLabel(for: dart), style: .hit)
                    }
                }
                Spacer()
                if engine.currentTurnTotal > 0 {
                    Text("= \(engine.currentTurnTotal)")
                        .font(DartsFont.mono(12, weight: .medium))
                        .foregroundStyle(Color.dPurpleLight)
                }
            }
            HStack(spacing: 6) {
                Text("Checkout:")
                    .font(DartsFont.sans(10))
                    .foregroundStyle(Color.dTextDim)
                Text(engine.checkoutForCurrentPlayer ?? "—")
                    .font(DartsFont.mono(11, weight: .medium))
                    .foregroundStyle(Color.dPurpleLight)
                Spacer()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }

    private func pillLabel(for dart: DartData) -> String {
        switch dart.multiplier {
        case .triple: return "T\(dart.score / 3)"
        case .double: return "D\(dart.score / 2)"
        case .bull:   return dart.score == 50 ? "Bull" : "25"
        case .single: return "\(dart.score)"
        }
    }
}
