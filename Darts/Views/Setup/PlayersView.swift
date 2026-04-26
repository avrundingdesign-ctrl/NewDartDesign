import SwiftUI

struct PlayersView: View {
    @EnvironmentObject var engine: GameEngine
    @State private var name: String = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Logo-Bereich
            VStack(spacing: 10) {
                LogoIcon()
                Text("Darts")
                    .font(DartsFont.sans(20, weight: .semibold))
                    .foregroundStyle(Color.dText)
                Text("Neues Spiel einrichten")
                    .font(DartsFont.sans(12))
                    .foregroundStyle(Color.dTextMuted)
            }
            .padding(.top, 32)
            .padding(.bottom, 16)

            StepProgress(active: 0, total: 3)

            // Sektion: Spieler
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "Spieler (min. 2, max. 4)")
                if engine.players.isEmpty {
                    Spacer().frame(height: 4)
                } else {
                    FlowLayout(spacing: 6) {
                        ForEach(Array(engine.players.enumerated()), id: \.element.id) { idx, p in
                            PlayerChip(name: p.name, index: idx) {
                                engine.removePlayer(at: idx)
                            }
                        }
                    }
                }

                HStack(spacing: 8) {
                    TextField("Name eingeben…", text: $name)
                        .focused($inputFocused)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit(addPlayer)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.dBg2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(inputFocused ? Color.dPurple : Color.white.opacity(0.1), lineWidth: 0.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .font(DartsFont.sans(13))
                        .foregroundStyle(Color.dText)
                        .tint(.dPurple)

                    Button(action: addPlayer) {
                        Text("Hinzufügen")
                            .font(DartsFont.sans(13, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.dPurple)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canAdd)
                    .opacity(canAdd ? 1 : 0.5)
                }
            }
            .padding(.horizontal, 18)

            Spacer()

            Button {
                inputFocused = false
                engine.goToMode()
            } label: {
                Text("Weiter — Modus wählen")
                    .dartsPrimaryButton(enabled: canProceed)
            }
            .buttonStyle(.plain)
            .disabled(!canProceed)
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.dBg1.ignoresSafeArea())
    }

    private var canAdd: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && engine.players.count < 4 &&
            !engine.players.contains(where: { $0.name.lowercased() == trimmed.lowercased() })
    }

    private var canProceed: Bool { engine.players.count >= 2 }

    private func addPlayer() {
        guard canAdd else { return }
        engine.addPlayer(name)
        name = ""
    }
}

// MARK: - Einfaches FlowLayout für Chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let w = proposal.width ?? 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var maxRowHeight: CGFloat = 0

        for sub in subviews {
            let s = sub.sizeThatFits(.unspecified)
            if rowWidth + s.width > w && rowWidth > 0 {
                totalHeight += maxRowHeight + spacing
                rowWidth = 0
                maxRowHeight = 0
            }
            rowWidth += s.width + spacing
            maxRowHeight = max(maxRowHeight, s.height)
        }
        totalHeight += maxRowHeight
        rowHeight = totalHeight
        return CGSize(width: w, height: rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var maxRowHeight: CGFloat = 0
        for sub in subviews {
            let s = sub.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += maxRowHeight + spacing
                maxRowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing
            maxRowHeight = max(maxRowHeight, s.height)
        }
    }
}
