import SwiftUI

struct GameView: View {
    @EnvironmentObject var engine: GameEngine

    @State private var showPauseMenu = false
    @State private var showCorrectionSheet = false

    var body: some View {
        VStack(spacing: 0) {
            cameraHeader
            ScoreCardRow()
            ThrowDisplay()
            actionRow
            manualRow
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.dBg1.ignoresSafeArea())
        .overlay(alignment: .top) {
            errorBanner
        }
        .overlay {
            if engine.bustFlash {
                BustToast(text: "BUST!")
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showPauseMenu) {
            PauseMenu(isPresented: $showPauseMenu)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.dBg1)
        }
        .sheet(isPresented: $showCorrectionSheet) {
            ScoreCorrectionSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .animation(.easeInOut(duration: 0.2), value: engine.bustFlash)
    }

    // MARK: - Header (Kamera-Vorschau)
    private var cameraHeader: some View {
        ZStack {
            CameraPreview(session: engine.cameraService.session)
                .frame(height: 200)
                .clipped()

            // Center-Ringe
            Circle()
                .stroke(Color.dPurple.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [3, 4]))
                .frame(width: 120, height: 120)
            Circle()
                .stroke(Color.dPurple.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
                .frame(width: 60, height: 60)

            // Top-Bar
            VStack {
                HStack {
                    statusBadge(text: "● \(engine.players.indices.contains(engine.currentPlayerIndex) ? engine.players[engine.currentPlayerIndex].name : "—") · \(engine.captureStatus.label)",
                                style: .info)
                    Spacer()
                    Button {
                        engine.speech.toggleMute()
                    } label: {
                        Image(systemName: engine.speech.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(engine.speech.isMuted ? Color.dRed : Color.dPurpleLight)
                            .frame(width: 28, height: 22)
                            .background(Color.dBg0.opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)

                    Button {
                        showPauseMenu = true
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.dPurpleLight)
                            .frame(width: 28, height: 22)
                            .background(Color.dBg0.opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)
                Spacer()
            }
        }
        .frame(height: 200)
        .background(Color.dBg0)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.dBorder).frame(height: 0.5)
        }
    }

    // MARK: - Status-Badge
    private enum BadgeStyle { case info, live }

    private func statusBadge(text: String, style: BadgeStyle) -> some View {
        Text(text)
            .font(DartsFont.mono(10))
            .foregroundStyle(style == .live ? Color.dGreen : Color.dPurpleLight)
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background((style == .live ? Color.dGreenDim : Color.dBg0.opacity(0.85)))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Action-Row (Scan + Undo)
    private var actionRow: some View {
        HStack(spacing: 8) {
            Button {
                engine.triggerManualScan()
            } label: {
                Text(engine.captureStatus == .uploading ? "Analysiere…" : "Foto analysieren")
                    .font(DartsFont.sans(13, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(engine.captureStatus == .uploading ? Color.dBg3 : Color.dPurple)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(engine.captureStatus == .uploading)
            .frame(maxWidth: .infinity)
            .layoutPriority(2)

            Button {
                showCorrectionSheet = true
            } label: {
                Text("✎ Korrigieren")
                    .font(DartsFont.sans(12))
                    .foregroundStyle(Color(white: 0.53))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Color.dBg3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8).stroke(Color.dBorder, lineWidth: 0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(engine.lastTurn == nil)
            .opacity(engine.lastTurn == nil ? 0.4 : 1)
            .frame(maxWidth: .infinity)
            .layoutPriority(1)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }

    // MARK: - Manual-Row (deaktiviert da Korrektur jetzt im Sheet liegt — Mockup-Stil bleibt für Vollständigkeit)
    private var manualRow: some View {
        HStack(spacing: 8) {
            HStack {
                Image(systemName: "info.circle")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.dTextDim)
                Text("Server liefert automatisch — manueller Override über „Korrigieren“.")
                    .font(DartsFont.sans(11))
                    .foregroundStyle(Color.dTextDim)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color.dBg2)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
    }

    // MARK: - Fehler-Banner
    @ViewBuilder
    private var errorBanner: some View {
        if let msg = engine.errorMessage {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.white)
                Text(msg)
                    .font(DartsFont.sans(12))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Spacer()
                Button {
                    engine.errorMessage = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.dRed.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
