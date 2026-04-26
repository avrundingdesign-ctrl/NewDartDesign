import SwiftUI

struct PauseMenu: View {
    @EnvironmentObject var engine: GameEngine
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("Spielmenü")
                    .font(DartsFont.sans(16, weight: .semibold))
                    .foregroundStyle(Color.dText)
                Text("Spieler \(engine.currentPlayerIndex + 1) · Runde \(engine.turnNumber)")
                    .font(DartsFont.sans(11))
                    .foregroundStyle(Color.dTextMuted)
            }
            .padding(.top, 18)
            .padding(.bottom, 14)

            VStack(spacing: 8) {
                MenuRow(title: engine.cameraService.isRunning ? "Pause" : "Fortsetzen",
                        icon: engine.cameraService.isRunning ? "pause.fill" : "play.fill") {
                    engine.togglePause()
                    isPresented = false
                }
                MenuRow(title: "Re-Kalibrieren",
                        icon: "scope") {
                    isPresented = false
                    engine.recalibrate()
                }
                MenuRow(title: engine.speech.isMuted ? "TTS einschalten" : "TTS stummschalten",
                        icon: engine.speech.isMuted ? "speaker.wave.2.fill" : "speaker.slash.fill") {
                    engine.speech.toggleMute()
                    isPresented = false
                }
                MenuRow(title: "Spiel beenden",
                        icon: "xmark.circle.fill",
                        destructive: true) {
                    isPresented = false
                    engine.backToSetup()
                }
            }
            .padding(.horizontal, 14)

            Button {
                isPresented = false
            } label: {
                Text("Schließen")
                    .dartsOutlineButton()
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 18)
        }
        .background(Color.dBg2)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 24)
    }
}

private struct MenuRow: View {
    let title: String
    let icon: String
    var destructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(destructive ? Color.dRed : Color.dPurpleLight)
                    .frame(width: 22)
                Text(title)
                    .font(DartsFont.sans(14))
                    .foregroundStyle(destructive ? Color.dRed : Color.dText)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.dTextDim)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color.dBg3)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}
