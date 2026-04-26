import SwiftUI

struct ScoreCorrectionSheet: View {
    @EnvironmentObject var engine: GameEngine
    @Environment(\.dismiss) private var dismiss

    @State private var darts: [DartCorrection] = (0..<3).map { _ in DartCorrection() }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Letzte Runde korrigieren")
                            .font(DartsFont.sans(15, weight: .semibold))
                            .foregroundStyle(Color.dText)
                        Text("Wert + Multiplikator je Dart wählen.")
                            .font(DartsFont.sans(11))
                            .foregroundStyle(Color.dTextMuted)
                    }

                    ForEach(0..<3, id: \.self) { idx in
                        DartRow(index: idx + 1, dart: $darts[idx])
                    }

                    HStack {
                        SectionLabel(text: "Summe")
                        Spacer()
                        Text("\(totalScore)")
                            .font(DartsFont.mono(18, weight: .semibold))
                            .foregroundStyle(Color.dPurpleLight)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.dBg2)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(18)
            }
            .background(Color.dBg1.ignoresSafeArea())
            .navigationTitle("Korrektur")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundStyle(Color.dTextMuted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Übernehmen") {
                        engine.correctLastTurn(darts: darts.map { ($0.computedValue, $0.multiplier) })
                        dismiss()
                    }
                    .foregroundStyle(Color.dPurpleLight)
                }
            }
        }
    }

    private var totalScore: Int { darts.map(\.computedValue).reduce(0, +) }
}

struct DartCorrection {
    var value: Int = 0
    var multiplier: DartData.Multiplier = .single

    var computedValue: Int {
        if multiplier == .bull { return value == 50 ? 50 : 25 }
        switch multiplier {
        case .single: return value
        case .double: return value * 2
        case .triple: return value * 3
        case .bull:   return value == 50 ? 50 : 25
        }
    }
}

private struct DartRow: View {
    let index: Int
    @Binding var dart: DartCorrection

    private let segments: [DartData.Multiplier] = [.single, .double, .triple, .bull]
    private let values = Array(0...20)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dart \(index)")
                .font(DartsFont.sans(12, weight: .medium))
                .foregroundStyle(Color.dText)

            // Multiplikator
            HStack(spacing: 6) {
                ForEach(segments, id: \.self) { m in
                    Button {
                        dart.multiplier = m
                        if m == .bull { dart.value = 25 }
                    } label: {
                        Text(label(for: m))
                            .font(DartsFont.sans(12, weight: .medium))
                            .foregroundStyle(dart.multiplier == m ? Color.dPurpleLight : Color.dTextMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(dart.multiplier == m ? Color.dPurpleDim : Color.dBg2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8).stroke(dart.multiplier == m ? Color.dPurple : Color.dBorder, lineWidth: 0.5)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Wert
            if dart.multiplier == .bull {
                HStack(spacing: 6) {
                    bullValueButton(label: "25", val: 25)
                    bullValueButton(label: "Bull (50)", val: 50)
                }
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                    ForEach(values, id: \.self) { v in
                        Button {
                            dart.value = v
                        } label: {
                            Text("\(v)")
                                .font(DartsFont.mono(12))
                                .foregroundStyle(dart.value == v ? Color.dPurpleLight : Color.dTextMuted)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(dart.value == v ? Color.dPurpleDim : Color.dBg2)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack {
                Spacer()
                Text("= \(dart.computedValue)")
                    .font(DartsFont.mono(13, weight: .medium))
                    .foregroundStyle(Color.dPurpleLight)
            }
        }
        .padding(12)
        .background(Color.dBg2)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func bullValueButton(label: String, val: Int) -> some View {
        Button {
            dart.value = val
        } label: {
            Text(label)
                .font(DartsFont.sans(12))
                .foregroundStyle(dart.value == val ? Color.dPurpleLight : Color.dTextMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(dart.value == val ? Color.dPurpleDim : Color.dBg2)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    private func label(for m: DartData.Multiplier) -> String {
        switch m {
        case .single: return "S"
        case .double: return "D"
        case .triple: return "T"
        case .bull:   return "Bull"
        }
    }
}
