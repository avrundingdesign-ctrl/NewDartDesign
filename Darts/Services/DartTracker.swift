import Foundation
import CoreGraphics

enum ScanResult {
    case sameRound
    case update([DartData])
}

final class DartTracker {

    private var history: [DartData] = []
    private var ignoredDarts: [DartData] = []
    private let tolerance: CGFloat = 20.0
    private let maxDarts = 3
    var onScoresUpdated: (([Int]) -> Void)?

    func merge(with newDarts: [DartData], isBusted: Bool) -> ScanResult {
        let historyOld = history

        // SCHRITT 1: Wenn Liste voll oder Bust → entscheiden ob Pfeile noch stecken (sameRound)
        // oder gezogen wurden (Reset).
        if newDarts.isEmpty && history.count == maxDarts {
            reset()
        }

        if history.count == maxDarts || isBusted {
            let connectionFound = newDarts.contains { newDart in
                history.contains { oldDart in
                    hypot(oldDart.x - newDart.x, oldDart.y - newDart.y) < tolerance
                }
            }
            if connectionFound {
                return .sameRound
            }
            history.removeAll()
            onScoresUpdated?([])
        }

        // SCHRITT 2: Neue Darts anhängen, Duplikate (Toleranz 20px) überspringen.
        for newDart in newDarts {
            if history.count >= maxDarts { break }
            let isDuplicate = history.contains { oldDart in
                hypot(oldDart.x - newDart.x, oldDart.y - newDart.y) < tolerance
            }
            if isDuplicate { continue }
            history.append(newDart)
            onScoresUpdated?(history.map { $0.score })
        }

        if historyOld.count == history.count {
            return .sameRound
        }
        return .update(history)
    }

    func reset() {
        ignoredDarts = history
        history.removeAll()
        onScoresUpdated?([])
    }

    func clearIgnored() {
        ignoredDarts.removeAll()
    }

    func getHistoryCount() -> Int {
        history.count
    }
}
