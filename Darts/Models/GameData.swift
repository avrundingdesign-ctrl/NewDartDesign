import Foundation
import CoreGraphics

// MARK: - Spielmodus (im Scope nur 301 & 501)
enum GameMode: String, CaseIterable, Identifiable {
    case x301 = "301"
    case x501 = "501"

    var id: String { self.rawValue }
    var startScore: Int { Int(rawValue) ?? 301 }
    var subtitle: String { "Double-Out" }
}

// MARK: - Keypoints des Boards (vom Server geliefert)
struct Keypoints: Equatable {
    var top: CGPoint
    var right: CGPoint
    var bottom: CGPoint
    var left: CGPoint

    init(top: CGPoint, right: CGPoint, bottom: CGPoint, left: CGPoint) {
        self.top = top; self.right = right; self.bottom = bottom; self.left = left
    }

    init?(server: ServerKeypoints) {
        let arrays = [server.top, server.right, server.bottom, server.left]
        guard arrays.allSatisfy({ $0.count == 2 }) else { return nil }
        self.top    = CGPoint(x: server.top[0],    y: server.top[1])
        self.right  = CGPoint(x: server.right[0],  y: server.right[1])
        self.bottom = CGPoint(x: server.bottom[0], y: server.bottom[1])
        self.left   = CGPoint(x: server.left[0],   y: server.left[1])
    }

    var asDict: [String: [CGFloat]] {
        [
            "top":    [top.x, top.y],
            "right":  [right.x, right.y],
            "bottom": [bottom.x, bottom.y],
            "left":   [left.x, left.y]
        ]
    }
}

// MARK: - Spielerzustand
struct Player: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var rest: Int = 0
    var legWins: Int = 0
    /// History aller fertigen Runden-Summen (für Average / Stats).
    var turnTotals: [Int] = []

    var average: Int {
        turnTotals.isEmpty ? 0 : Int((Double(turnTotals.reduce(0, +)) / Double(turnTotals.count)).rounded())
    }
    var bestTurn: Int { turnTotals.max() ?? 0 }
}

// MARK: - Game-Setup-Container (über alle Phasen erhalten)
struct GameSetup {
    var mode: GameMode = .x301
    var legsToPlay: Int = 1            // 1, 3 oder 5 (best of)
    /// Anzahl Legs, um zu gewinnen (ceil(legsToPlay / 2)).
    var legsToWin: Int { (legsToPlay + 1) / 2 }
    var doubleOut: Bool = true
    var keypoints: Keypoints? = nil
}

// MARK: - Snapshot eines abgeschlossenen Zugs (für Korrektur / Undo)
struct TurnSnapshot {
    let playerIndex: Int
    let scoreThrown: Int
    let previousRest: Int
    let isWin: Bool
    let isBust: Bool
    /// Anzahl Legs, die der Spieler vor diesem Zug bereits gewonnen hatte (für Win-Undo).
    let previousLegWins: Int
}

// MARK: - App-Phase (5 Mockup-Pages + Zwischenpunkte)
enum AppPhase: Equatable {
    case permission
    case players
    case mode
    case calibration
    case playing
    case legTransition(winner: String, leg: Int)
    case won(winner: String)
}

// MARK: - Capture-Status (für UI-Indikator im Game-View)
enum CaptureStatus {
    case idle           // Spiel pausiert
    case stilling       // wartet auf Stillstand
    case ready          // bereit, gleich kommt Capture
    case capturing      // Foto wird gemacht
    case uploading      // Bild wird hochgeladen / analysiert

    var label: String {
        switch self {
        case .idle:      return "Pausiert"
        case .stilling:  return "Halte still …"
        case .ready:     return "Bereit"
        case .capturing: return "Foto …"
        case .uploading: return "Analysiere …"
        }
    }
}
