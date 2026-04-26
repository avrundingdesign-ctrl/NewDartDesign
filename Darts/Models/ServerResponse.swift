import Foundation
import CoreGraphics

struct ServerResponse: Codable {
    var keypoints: ServerKeypoints
    var darts: [DartData]
}

struct ServerKeypoints: Codable {
    var top: [CGFloat]
    var right: [CGFloat]
    var bottom: [CGFloat]
    var left: [CGFloat]
}

struct DartData: Codable, Identifiable, Equatable {
    var id = UUID()
    var x: CGFloat
    var y: CGFloat
    var score: Int
    var field_type: String

    private enum CodingKeys: String, CodingKey {
        case x, y, score, field_type
    }

    /// Multiplikator-Klassifikation für Double-Out-Validierung.
    enum Multiplier: String { case single, double, triple, bull }

    var multiplier: Multiplier {
        switch field_type.lowercased() {
        case "double": return .double
        case "triple": return .triple
        case "bull", "bullseye": return .bull
        default: return .single
        }
    }
}
