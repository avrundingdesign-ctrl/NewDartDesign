import SwiftUI

@main
struct DartsApp: App {
    @StateObject private var engine = GameEngine()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(engine)
                .preferredColorScheme(.dark)
                .background(Color.dBg0.ignoresSafeArea())
        }
    }
}
