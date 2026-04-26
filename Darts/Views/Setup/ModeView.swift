import SwiftUI

struct ModeView: View {
    @EnvironmentObject var engine: GameEngine

    private let legOptions = [1, 3, 5]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("Spielmodus")
                    .font(DartsFont.sans(20, weight: .semibold))
                    .foregroundStyle(Color.dText)
                Text("Wähle einen Modus und Leg-Anzahl")
                    .font(DartsFont.sans(12))
                    .foregroundStyle(Color.dTextMuted)
            }
            .padding(.top, 24)
            .padding(.bottom, 12)

            StepProgress(active: 1, total: 3)

            VStack(alignment: .leading, spacing: 14) {
                SectionLabel(text: "Modus")
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    ForEach(GameMode.allCases) { mode in
                        ModeCard(
                            title: mode.rawValue,
                            subtitle: mode.subtitle,
                            isSelected: engine.setup.mode == mode
                        ) {
                            engine.setMode(mode)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 14)

            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "Legs zum Sieg")
                HStack(spacing: 8) {
                    ForEach(legOptions, id: \.self) { n in
                        LegsButton(
                            label: "Best of \(n)",
                            isSelected: engine.setup.legsToPlay == n
                        ) {
                            engine.setLegs(n)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)

            Spacer()

            HStack(spacing: 8) {
                Button {
                    engine.phase = .players
                } label: {
                    Text("Zurück")
                        .font(DartsFont.sans(14, weight: .medium))
                        .foregroundStyle(Color.dTextMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.dBg2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12).stroke(Color.dBorder, lineWidth: 0.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                Button {
                    engine.goToCalibration()
                } label: {
                    Text("Spiel starten →")
                        .dartsPrimaryButton()
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.dBg1.ignoresSafeArea())
    }
}
