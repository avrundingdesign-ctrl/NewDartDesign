import SwiftUI

struct ScoreCardRow: View {
    @EnvironmentObject var engine: GameEngine

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(engine.players.enumerated()), id: \.element.id) { idx, player in
                ScoreCard(
                    player: player,
                    isActive: idx == engine.currentPlayerIndex,
                    legsToWin: engine.setup.legsToWin
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }
}

private struct ScoreCard: View {
    let player: Player
    let isActive: Bool
    let legsToWin: Int

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                Text(player.name)
                    .font(DartsFont.sans(10))
                    .foregroundStyle(Color.dTextMuted)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text("\(player.rest)")
                    .font(DartsFont.mono(28, weight: .semibold))
                    .foregroundStyle(Color.dText)
                Text("⌀ \(player.average)")
                    .font(DartsFont.sans(9))
                    .foregroundStyle(Color.dTextDim)
                    .padding(.top, 2)
                HStack(spacing: 3) {
                    ForEach(0..<legsToWin, id: \.self) { i in
                        Circle()
                            .fill(i < player.legWins ? Color.dPurple : Color.dBg3)
                            .frame(width: 7, height: 7)
                    }
                }
                .padding(.top, 5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .background(Color.dBg2)
            .overlay(
                RoundedRectangle(cornerRadius: 12).stroke(isActive ? Color.dPurple : Color.dBorder, lineWidth: isActive ? 1 : 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if isActive {
                Circle()
                    .fill(Color.dPurple)
                    .frame(width: 5, height: 5)
                    .padding(8)
            }
        }
    }
}
