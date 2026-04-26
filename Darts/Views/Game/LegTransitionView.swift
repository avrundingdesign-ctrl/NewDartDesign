import SwiftUI

struct LegTransitionView: View {
    @EnvironmentObject var engine: GameEngine
    let winnerName: String
    let legNumber: Int

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(Color.dPurpleLight)
                    .padding(.top, 20)
                Text("Leg \(legNumber) gewonnen!")
                    .font(DartsFont.sans(11, weight: .regular))
                    .foregroundStyle(Color.dPurpleLight)
                    .tracking(1)
                    .textCase(.uppercase)
                Text(winnerName)
                    .font(DartsFont.sans(28, weight: .semibold))
                    .foregroundStyle(Color.dText)

                HStack(spacing: 8) {
                    ForEach(engine.players) { player in
                        VStack(spacing: 2) {
                            Text(player.name)
                                .font(DartsFont.sans(10))
                                .foregroundStyle(Color.dTextMuted)
                            Text("\(player.legWins)")
                                .font(DartsFont.mono(20, weight: .semibold))
                                .foregroundStyle(Color.dText)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.dBg2)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.top, 4)

                Button {
                    engine.startNextLeg()
                } label: {
                    Text("Nächstes Leg starten")
                        .dartsPrimaryButton()
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
            }
            .frame(maxWidth: 320)
            .background(Color.dBg1)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18).stroke(Color.dPurple, lineWidth: 0.5)
            )
            .padding(.horizontal, 28)
        }
        .transition(.opacity)
    }
}
