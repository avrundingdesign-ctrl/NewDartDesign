import SwiftUI

struct RootView: View {
    @EnvironmentObject var engine: GameEngine

    var body: some View {
        ZStack {
            Color.dBg1.ignoresSafeArea()
            content
                .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.25), value: phaseKey)
        .onAppear {
            if case .permission = engine.phase {
                engine.bootstrapAfterPermissionCheck()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch engine.phase {
        case .permission:
            PermissionOnboarding()
        case .players:
            PlayersView()
        case .mode:
            ModeView()
        case .calibration:
            CalibrationView()
        case .playing:
            GameView()
        case .legTransition(let winner, let leg):
            ZStack {
                GameView()
                LegTransitionView(winnerName: winner, legNumber: leg)
            }
        case .won(let winner):
            WinnerView(winnerName: winner)
        }
    }

    private var phaseKey: String {
        switch engine.phase {
        case .permission:           return "permission"
        case .players:              return "players"
        case .mode:                 return "mode"
        case .calibration:          return "calibration"
        case .playing:              return "playing"
        case .legTransition:        return "legTransition"
        case .won:                  return "won"
        }
    }
}
