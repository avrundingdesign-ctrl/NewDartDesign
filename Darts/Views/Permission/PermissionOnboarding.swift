import SwiftUI
import AVFoundation
import UIKit

struct PermissionOnboarding: View {
    @EnvironmentObject var engine: GameEngine
    @State private var status: AVAuthorizationStatus = CameraService.cameraAuthorizationStatus()

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            LogoIcon()
            VStack(spacing: 6) {
                Text("Darts")
                    .font(DartsFont.sans(20, weight: .semibold))
                    .foregroundStyle(Color.dText)
                Text("Kamera-Zugriff für die automatische Wurf-Erkennung")
                    .font(DartsFont.sans(12))
                    .foregroundStyle(Color.dTextMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }

            VStack(alignment: .leading, spacing: 14) {
                bulletPoint(
                    title: "Lokale Kamera",
                    body: "Wir nehmen während des Spiels Fotos vom Board auf."
                )
                bulletPoint(
                    title: "Erkennung am Server",
                    body: "Die Bilder gehen verschlüsselt an den DartVision-Server, der die Würfe und Punkte zurückliefert."
                )
                bulletPoint(
                    title: "Keine Speicherung",
                    body: "Die Bilder verlassen das Gerät nur für die Score-Erkennung."
                )
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 18)
            .background(Color.dBg2)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 18)

            Spacer()

            Button(action: requestPermission) {
                Text(status == .denied ? "Einstellungen öffnen" : "Kamera-Zugriff erlauben")
                    .dartsPrimaryButton()
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 18)

            if status == .denied {
                Text("Du hast den Zugriff verweigert. Aktiviere ihn in den iOS-Einstellungen unter Datenschutz → Kamera.")
                    .font(DartsFont.sans(11))
                    .foregroundStyle(Color.dTextMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 14)
            } else {
                Spacer().frame(height: 14)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.dBg1.ignoresSafeArea())
    }

    private func bulletPoint(title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle().fill(Color.dPurple).frame(width: 6, height: 6).padding(.top, 6)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DartsFont.sans(13, weight: .medium))
                    .foregroundStyle(Color.dText)
                Text(body)
                    .font(DartsFont.sans(12))
                    .foregroundStyle(Color.dTextMuted)
            }
        }
    }

    private func requestPermission() {
        switch status {
        case .notDetermined:
            Task {
                let granted = await CameraService.requestCameraAccess()
                await MainActor.run {
                    status = CameraService.cameraAuthorizationStatus()
                    if granted { engine.phase = .players }
                }
            }
        case .denied, .restricted:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        case .authorized:
            engine.phase = .players
        @unknown default:
            break
        }
    }
}
