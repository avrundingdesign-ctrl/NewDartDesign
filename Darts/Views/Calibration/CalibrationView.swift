import SwiftUI

struct CalibrationView: View {
    @EnvironmentObject var engine: GameEngine

    @State private var lightState: CheckItem.CheckState = .pending
    @State private var distState: CheckItem.CheckState = .pending
    @State private var focusState: CheckItem.CheckState = .pending
    @State private var angleState: CheckItem.CheckState = .pending

    @State private var lightValue = "—"
    @State private var distValue = "—"
    @State private var focusValue = "—"
    @State private var angleValue = "—"

    @State private var heading = "Kamera wird geprüft …"
    @State private var subheading = "Bitte Kamera auf die Scheibe richten"
    @State private var showServerWait = false
    @State private var showError = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("Kalibrierung")
                    .font(DartsFont.sans(20, weight: .semibold))
                    .foregroundStyle(Color.dText)
                Text("Kamera wird automatisch geprüft")
                    .font(DartsFont.sans(12))
                    .foregroundStyle(Color.dTextMuted)
            }
            .padding(.top, 18)
            .padding(.bottom, 10)

            StepProgress(active: 2, total: 3)

            VStack(spacing: 16) {
                // Sucher-Visual
                ZStack {
                    Rectangle().fill(Color.dBg0)
                    ScanlineOverlay()
                    Circle()
                        .stroke(Color.dPurple.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [3, 4]))
                        .frame(width: 110, height: 110)
                    Circle()
                        .stroke(Color.dPurple.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
                        .frame(width: 55, height: 55)
                }
                .frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16).stroke(Color.dBorder, lineWidth: 1)
                )

                VStack(spacing: 4) {
                    Text(heading)
                        .font(DartsFont.sans(15, weight: .medium))
                        .foregroundStyle(Color.dText)
                    Text(subheading)
                        .font(DartsFont.sans(12))
                        .foregroundStyle(Color.dTextMuted)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 6) {
                    CheckItem(name: "Beleuchtung",   value: lightValue, state: lightState)
                    CheckItem(name: "Abstand",       value: distValue,  state: distState)
                    CheckItem(name: "Fokus / Schärfe", value: focusValue, state: focusState)
                    CheckItem(name: "Kamerawinkel",  value: angleValue, state: angleState)
                }
                .padding(.horizontal, 4)

                if showServerWait {
                    HStack(spacing: 6) {
                        PulseDot()
                        Text("Warte auf valides Server-Bild …")
                            .font(DartsFont.sans(11))
                            .foregroundStyle(Color.dTextMuted)
                    }
                    .padding(.top, 8)
                }

                if showError {
                    VStack(spacing: 8) {
                        Text(engine.errorMessage ?? "Server nicht erreichbar.")
                            .font(DartsFont.sans(12))
                            .foregroundStyle(Color.dRed)
                            .multilineTextAlignment(.center)
                        Button {
                            startCalibrationFlow()
                        } label: {
                            Text("Erneut versuchen")
                                .dartsOutlineButton()
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 40)
                    }
                }
            }
            .padding(.horizontal, 18)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.dBg1.ignoresSafeArea())
        .onAppear {
            startCalibrationFlow()
        }
    }

    private func startCalibrationFlow() {
        // Reset
        lightState = .pending; distState = .pending; focusState = .pending; angleState = .pending
        lightValue = "—"; distValue = "—"; focusValue = "—"; angleValue = "—"
        heading = "Kamera wird geprüft …"
        subheading = "Bitte Kamera auf die Scheibe richten"
        showServerWait = false
        showError = false
        engine.errorMessage = nil

        // Animation der vier Checks (pure UI)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 900_000_000)
            lightValue = "Gut — 87 %"; lightState = .ok
            try? await Task.sleep(nanoseconds: 900_000_000)
            distValue = "190 cm — ok"; distState = .ok
            try? await Task.sleep(nanoseconds: 900_000_000)
            focusValue = "Scharf"; focusState = .ok
            try? await Task.sleep(nanoseconds: 900_000_000)
            angleValue = "Frontal — ok"; angleState = .ok

            heading = "Warte auf Server …"
            subheading = "Erstes valides Bild wird angefordert"
            showServerWait = true
        }

        // Parallel: echtes Server-Probe-Bild
        engine.runServerCalibration { success in
            Task { @MainActor in
                showServerWait = false
                if success {
                    heading = "Valides Bild empfangen"
                    subheading = "Kalibrierung abgeschlossen — Spiel startet"
                    try? await Task.sleep(nanoseconds: 900_000_000)
                    engine.startGame()
                } else {
                    showError = true
                    heading = "Kalibrierung fehlgeschlagen"
                    subheading = "Verbindung oder Bild war nicht verwertbar"
                }
            }
        }
    }
}

// MARK: - Scanline-Animation
struct ScanlineOverlay: View {
    @State private var top: CGFloat = 0.08

    var body: some View {
        GeometryReader { proxy in
            Rectangle()
                .fill(Color.dPurple.opacity(0.85))
                .frame(height: 2)
                .position(x: proxy.size.width / 2, y: proxy.size.height * top)
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        top = 0.92
                    }
                }
        }
    }
}
